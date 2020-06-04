/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/
--Problema shrink

--2555


DBCC TRACEON(2546, -1) --LIGA MINI-DUMP
go 
DBCC DUMPTRIGGER('set', 8134) --LIGA TRIGGER ERRO XXXX
GO

GO
SELECT 1/0 -- ERRO

GO
DBCC DUMPTRIGGER('clear', 8134) --DESLIGA TRIGGER ERRO XXXX
GO
DBCC TRACEOFF(2546, -1)  --DESLIGA MINI-DUMP
go 



DBCC TRACEON(2546, -1) --LIGA MINI-DUMP
go 
DBCC DUMPTRIGGER('set', 2555) --LIGA TRIGGER ERRO XXXX
GO

SELECT 1/0 -- ERRO

GO
DBCC DUMPTRIGGER('clear', 2555) --DESLIGA TRIGGER ERRO XXXX
GO
DBCC TRACEOFF(2546, -1)  --DESLIGA MINI-DUMP
go 
