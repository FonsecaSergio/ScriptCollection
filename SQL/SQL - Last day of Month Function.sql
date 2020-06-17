/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-06-17
************************************************/

DROP FUNCTION IF EXISTS [dbo].[GetLastDayOfMonth]
GO

--SELECT dbo.GetLastDayOfMonth ('2011-01-05')
--SELECT dbo.GetLastDayOfMonth ('2011-01-30')
--SELECT dbo.GetLastDayOfMonth ('2011-02-05')

CREATE FUNCTION [dbo].[GetLastDayOfMonth]
(
	@DATA DATE
) RETURNS DATE
AS
BEGIN
	DECLARE @ThisMonthFirstDay as DATE = CONVERT(VARCHAR(8), @DATA, 120) + '01'
	DECLARE @NextMonthFirstDay as DATE = DATEADD(MONTH, 1, @ThisMonthFirstDay)
	RETURN DATEADD(DAY, -1, @NextMonthFirstDay) 
END

GO
