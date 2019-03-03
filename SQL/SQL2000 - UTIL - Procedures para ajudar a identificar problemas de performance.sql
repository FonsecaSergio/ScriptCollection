/******************************************************************************************************
Este script cria duas procedures que são excelentes para ajudar a identificar problemas de performance:

sp_usrinputbuffer: Esta procedure permite identificar a instrução exata que está sendo executado por uma dada 
conexão. Semelhante ao DBCC INPUTBUFFER mas diferente desta, em caso de procedure, a proc mostra toda a instrução 
inteira e não apenas o nome da procedure.

Aqui ela será utilizada em conjunto com a proc principal (sp_usrtrackusers) mas pode ser executada individualmente passando
como parâmetro o SPID. Exemplo: sp_usrinputbuffer 54 (Onde 54 é o ID da conexão SPID)

sp_usrtrackusers: Esta procedure identifica todas as conexões ativas no servidor e mostra a instrução que cada uma delas
estão executando. É ideal para identificar qual conexão está impactando na performace do servidor.

Exemplo: sp_usrtrackusers

Criada em 01/04/2005
Autor: Nilton Pinheiro
WebSite: http://www.mcdbabrasil.com.br

**********************************************************************************************************/
USE MASTER
GO
-- Cria procedure de apoio sp_usrinputbuffer a qual será usada pela proc sp_who4
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_usrinputbuffer]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[sp_usrinputbuffer]
GO
CREATE PROCEDURE dbo.sp_usrinputbuffer
(
	@SPID smallint,		-- O SPID a ser analizado
	@WAIT tinyint = 1,	-- Intervalo de repetição entre as verificações.Valor deve estar entre 0 e 60 segundos
				-- Default é de 1 em 1 segundo
	@NoLoop bit = 1		-- Se =1, o SPID é analizado apenas uma vez. Se =0 fica em loop até o final do processo.
)
AS
BEGIN

/********************************************************************************************
sp_usrinputbuffer: Esta procedure permite identificar a instrução exata que está sendo 
executado por uma dada conexão. Semelhante ao DBCC INPUTBUFFER mas diferente desta, em caso 
de procedure, a proc mostra toda a instrução inteira e não apenas o nome da procedure.

Exemplo: sp_usrinputbuffer 54 (Onde 54 é o ID da conexão SPID)

Obs: Se preferir, esta pode ser criada em qualquer base, porém, ao executá-la deverá passar o nome da
base onde a mesma se encontra. Exemplo: Base..sp_usrinputbuffer 54

Author Original: Narayana Vyas Kondreddi
Source: http://vyaskn.tripod.com
Date Created: 18/12/2003
Alterada por : Nilton Pinheiro
WebSite: http://www.mcdbabrasil.com.br
*********************************************************************************************/	
	 
	SET NOCOUNT ON
 
	DECLARE @sql_handle binary(20), @handle_found bit
	DECLARE @stmt_start int, @stmt_end int
	DECLARE @line varchar(8000), @wait_str varchar(8)
 
	SET @handle_found = 0
 
	IF @WAIT NOT BETWEEN 0 AND 60
	BEGIN
		RAISERROR('Valores válidos para @WAIT estão entre 0 e 60 segundos', 16, 1)
		RETURN -1
	END
	ELSE
	BEGIN
		SET @wait_str = '00:00:' + RIGHT('00' + CAST(@WAIT AS varchar(2)), 2)
	END
 
	WHILE 1 = 1
	BEGIN
		SELECT	@sql_handle = sql_handle,
			@stmt_start = stmt_start/2,
			@stmt_end = CASE WHEN stmt_end = -1 THEN -1 ELSE stmt_end/2 END
			FROM master.dbo.sysprocesses
			WHERE	spid = @SPID
				AND ecid = 0
  
		IF @sql_handle = 0x0
		BEGIN
			IF @handle_found = 0
			BEGIN
				RAISERROR('Não pode encontrar o handle ou o SPID é inválido', 16, 1)
				RETURN -1
			END
			ELSE
			BEGIN
				RAISERROR('Query/Stored procedure completada', 0, 1)
				RETURN 0
			END
		END
		ELSE
		BEGIN
			SET @handle_found = 1
		END
 		Print '******** STATEMENT SENDO EXECUTADO NO MOMENTO ************'
		Print ''
		SET @line = 
		(
			SELECT 
				SUBSTRING(	text,
						COALESCE(NULLIF(@stmt_start, 0), 1),
						CASE @stmt_end 
							WHEN -1 
								THEN DATALENGTH(text) 
							ELSE 
								(@stmt_end - @stmt_start) 
    						END
					) 
   			FROM ::fn_get_sql(@sql_handle)
  		)
 
		Print @line
 
		IF @NoLoop = 1
		BEGIN
			RETURN 0
		END
 
		WAITFOR DELAY @wait_str
 
	END
 
END

GO

-- Cria procedure principal sp_usrtrackusers
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_usrtrackusers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[sp_usrtrackusers]
GO
CREATE PROCEDURE dbo.sp_usrtrackusers
AS
Begin

/***********************************************************************************
Esta procedure identifica todas as conexões ativas no servidor e 
mostra a instrução que cada uma delas estão executando. É ideal para identificar 
qual conexão está impactando na performace do servidor.

Exemplo: sp_usrtrackusers

Obs: Se preferir, esta pode ser criada em qualquer base, porém, ao executá-la deverá passar o nome da
base onde a mesma se encontra. Exemplo: Base..sp_usrtrackusers

Criada em 01/04/2005
Autor: Nilton Pinheiro
WebSite: http://www.mcdbabrasil.com.br

***************************************************/
Set NoCount On
declare @spid	smallint,
	@ecid			smallint,
	@blocked		smallint,
	@DbName 		VarChar(15),
	@loginame	VarChar(15),
	@hostname	VarChar(15),
	@program_name	VarChar(50),
	@cpu			int,
	@physical_io bigint,
	@memusage	int,
	@login_time	datetime,
	@last_batch	datetime


Declare C_CONN CURSOR for 
	Select SPID,
	ECID,
	blocked,
	Cast(DB_Name(DbId) as VarChar(15)) AS Banco,
	Cast(loginame as VarChar(15)) as LogiName,
	Cast(HostName as VarChar(15)) as HostName, 
	Cast(program_name as VarCHar(50)) as Program_Name,
	cpu,
	physical_io,
	memusage,
	login_time,
	last_batch
from master..sysprocesses where KPID <>0

Open C_Conn
Fetch from C_CONN into @spid, @ecid, @blocked, @DbName, @loginame, @hostname, @program_name, @cpu, @physical_io, @memusage, @login_time, @last_batch
While @@Fetch_Status = 0 
Begin 
Select @SPID as SPID, 
	@ecid as ecid, 
	@blocked as Blocked,
	@DbName 	as Banco, 
	@loginame as LogiName,
	@hostname as HostName,
	@program_name as Program_Name,
	@cpu as CPU,
	@physical_io as Physical_IO,
	@memusage  as [MemUsage],
	@login_time as Login_Time,
	@last_batch	as Last_Batch,
	datediff (mi,@last_batch,getDate() ) as RunAs

-- Se criar a proc em outra base, deve mudar de master para a base onde a proc foi criada.	
exec master..sp_usrinputbuffer @spid

print ''
print ''
print ''
Fetch NEXT from C_CONN into @spid, @ecid, @blocked, @DbName, @loginame, @hostname, @program_name, @cpu, @physical_io, @memusage, @login_time, @last_batch
End
CLOSE C_CONN
DEALLOCATE C_CONN
end
GO