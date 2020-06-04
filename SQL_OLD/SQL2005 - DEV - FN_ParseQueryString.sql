IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_ParseQueryString]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[FN_ParseQueryString]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[FN_ParseQueryString]
(
	 @TX_QUERY_STRING as VARCHAR(500)
	,@TX_SPLITTER as CHAR(1) = '&'
)
RETURNS @TB_QUERY_DATA TABLE
(
	 TX_KEY VARCHAR(50)
	,TX_VALUE VARCHAR(500)
)
AS
BEGIN

	DECLARE @TX_AUX_STRING as VARCHAR(500)
	DECLARE @TX_AUX_DATA as VARCHAR(500)
	SET @TX_AUX_STRING = @TX_QUERY_STRING

	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--Faz loop buscando os N parametros
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	WHILE @TX_AUX_STRING LIKE '%' + @TX_SPLITTER + '%'
	BEGIN
		--Retorna parametro no formato "Value=parametro"
		SET @TX_AUX_DATA = SUBSTRING(@TX_AUX_STRING, 1, CHARINDEX(@TX_SPLITTER,@TX_AUX_STRING) - 1)
		
		INSERT INTO @TB_QUERY_DATA (TX_KEY,TX_VALUE)
		SELECT 
			 SUBSTRING(@TX_AUX_DATA, 1, CHARINDEX('=',@TX_AUX_DATA) - 1) as TX_KEY
			,SUBSTRING(@TX_AUX_DATA, CHARINDEX('=',@TX_AUX_DATA) + 1, 500) as TX_VALUE
		
		--Elimita parametro	
		SET @TX_AUX_STRING = SUBSTRING(@TX_AUX_STRING, CHARINDEX(@TX_SPLITTER,@TX_AUX_STRING) + 1,500 )
	END

	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--Busca ultimo parametro
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	BEGIN
		--Retorna parametro no formato "Value=parametro"
		SET @TX_AUX_DATA = SUBSTRING(@TX_AUX_STRING, 1, 500)
			
		INSERT INTO @TB_QUERY_DATA (TX_KEY,TX_VALUE)
		SELECT 
			 SUBSTRING(@TX_AUX_DATA, 1, CHARINDEX('=',@TX_AUX_DATA) - 1) as TX_KEY
			,SUBSTRING(@TX_AUX_DATA, CHARINDEX('=',@TX_AUX_DATA) + 1, 500) as TX_VALUE
	END
	
	RETURN
END

GO



SELECT * FROM dbo.FN_ParseQueryString ('Value1=parametro1&Value2=parametro2&Value3=parametro3','&')
SELECT * FROM FN_ParseQueryString ('Value1=parametro1+Value2=parametro2+Value3=parametro3','+')
