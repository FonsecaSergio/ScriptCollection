/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-06-17
************************************************/

SET LANGUAGE Portuguese
GO
SELECT DATENAME(dd,GETDATE()) + ' de ' + DATENAME(mm,GETDATE()) + ' de ' + CAST(YEAR(GETDATE()) AS CHAR(4))


SET LANGUAGE English
GO
SELECT DATENAME(dd,GETDATE()) + ', ' + DATENAME(mm,GETDATE()) + ' ' + CAST(YEAR(GETDATE()) AS CHAR(4))

