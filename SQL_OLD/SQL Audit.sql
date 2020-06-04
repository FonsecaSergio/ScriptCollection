Como estávamos conversando além da solução que o Sergio havia lhe passado, é possível criar auditoria.

Para criar a auditoria por banco de dados, é preciso executar o script com o “CREATE DATABASE AUDIT SPECIFICATION” banco por banco.

1)	Cria-se uma auditoria por servidor. Nesta auditoria você define o tamanho máximo do arquivo, quantos arquivos de auditoia e o delay de gravação. No exemplo que estou te enviando o Delay é de 1 segundo, o arquivo está sendo gerado na pasta c:\auditoria e o tamanho máximo é de 2MB por arquivo, sendo que serão gerados apenas 2 arquivos.
2)	Voce pode configurar a auditoria de servidor para rastrear o LOGIN\LOGOUT mas dessa forma você não vai enxergar em que banco ocorreu o LOGIN\LOGOUT, logo eu comentei essa parte do script.
3)	Para rastrear por banco de dados, a auditoria no SQL 2008 deverá ser configurada para avaliar toda a vez que ocorre um exec, select, insert ou um update no banco de dados. Dessa forma você vai obter todos os usuários que estão fazendo alguma dessas operações dentro do banco de dados.
4)	O Select no final  na função sys.fn_get_audit_file , é para ler o arquivo de auditoria que está sendo gerado. VOce pode criar um Job e que copia este arquivo para um banco de dados, existe um exemplo montado pela equipe do SQLCAT baseado num Whitepaper da Microsoft.

SQL CAT - http://sqlcat.codeplex.com/wikipage?title=sqlauditcentral&referringTitle=Home
Doc MS - http://www.microsoft.com/en-us/download/details.aspx?id=6808




-------------------------------------------------------------------------------------------------------
--Server Audit
-------------------------------------------------------------------------------------------------------
GO
USE [master]
GO
       -------------------------------------------------------------
       --ALTER SERVER AUDIT [Audit-Server-Lab] WITH (STATE = OFF)
       --GO
       --DROP SERVER AUDIT [Audit-Server-Lab]
       --GO
       -------------------------------------------------------------
       
IF NOT EXISTS 
             (SELECT 1 FROM sys.dm_server_audit_status
             WHERE NAME = 'Audit-Server-Lab' 
              )

       CREATE SERVER AUDIT [Audit-Server-Lab]
       TO FILE 
                    (      FILEPATH = N'C:\Auditoria\' ---> cria arquivo de auditoria neste caminho
                           ,MAXSIZE = 2 MB --> tamanho maximo do arquivo
                           ,MAX_ROLLOVER_FILES = 2 --. numero maximo de arquivos a serem retidos no sistema
                           ,RESERVE_DISK_SPACE = OFF --> pre aloca um tamanho de arquivo no disco.
                    )
       WITH
                    (      QUEUE_DELAY = 1000 --> valor minimo de atraso da auditoria... Sincrono = 0. No caso espera até 1000 milesegundos para começar.
                           ,ON_FAILURE = CONTINUE ---> indica se instancia deve parar ou continuar se houver falha na auditoria.
                    )


       ALTER SERVER AUDIT [Audit-Server-Lab] WITH (STATE = on)
GO

----------------------------------------------------------------------------------------------------------------
--Auditoria por login
IF NOT EXISTS 
             (SELECT * FROM sys.server_audit_specifications  
             WHERE NAME = 'ServerAuditSpecification-Lab-Login' 
              )

--CREATE SERVER AUDIT SPECIFICATION [ServerAuditSpecification-Lab-Login]
--FOR SERVER AUDIT [Audit-Server-Lab]
--ADD (SUCCESSFUL_LOGIN_GROUP),
--ADD (FAILED_LOGIN_GROUP)
--WITH (STATE = ON)
--GO

use teste
go
CREATE DATABASE AUDIT SPECIFICATION [DatabaseAuditSpecification-lAB]
FOR SERVER AUDIT [Audit-Server-Lab]
ADD (EXECUTE ON DATABASE::[teste] BY public),
ADD (SELECT ON DATABASE::[teste] BY public),
ADD (INSERT ON DATABASE::[teste] BY public),
ADD (UPDATE ON DATABASE::[teste] BY public),
ADD (DELETE ON DATABASE::[teste] BY public)
WITH (STATE = ON)
go


SELECT --*
       DATEADD(hh, DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP),    event_time  ) as corrected_time  
       ,event_time
       ,action_id 
       ,session_server_principal_name AS UserName 
       ,server_instance_name 
       ,database_name 
       ,schema_name 
       ,object_name 
       ,statement 
       , server_principal_name
       ,additional_information 
       ,user_defined_information 
FROM sys.fn_get_audit_file('C:\Auditoria\*.sqlaudit', DEFAULT, DEFAULT) 
