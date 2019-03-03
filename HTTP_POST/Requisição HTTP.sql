------------------------------------------------------------------------------
-- POST::HTTP
------------------------------------------------------------------------------
-- Autor: Sergio C Fonseca
-- Data: 05/01/2006
------------------------------------------------------------------------------

DECLARE @SERVER as VARCHAR(500)
DECLARE @REQUISICAO as VARCHAR(500)

SET @SERVER = 'http://tito:8080/Vosprepaid/Request.asp'
SET @REQUISICAO = 'action=login&user=adm&password=1234'


CREATE TABLE #TEMP (OUTPUT VARCHAR(8000))


DECLARE @QUERY VARCHAR(8000)
SET @QUERY = 'cmd /k cscript.exe "C:\Sérgio\VoxAge\2734 - Requisição HTTP - Prepaid\script.vbs" ' + 
		   '"' + @SERVER + '" "' + @REQUISICAO + '"'

INSERT INTO #TEMP
EXEC master..xp_cmdshell @QUERY

SELECT * FROM #TEMP
WHERE OUTPUT LIKE 'MESSAGE: %'

SELECT 
	SUBSTRING([OUTPUT], 9, 8000) as RESULTADO
FROM #TEMP
WHERE OUTPUT LIKE 'RESULT: %'

DROP TABLE #TEMP