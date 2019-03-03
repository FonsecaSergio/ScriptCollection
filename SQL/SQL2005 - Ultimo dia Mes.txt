IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[IGCF_GetLastDayOfMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[IGCF_GetLastDayOfMonth]
GO

--SELECT dbo.IGCF_GetLastDayOfMonth ('2011-01-05')
--SELECT dbo.IGCF_GetLastDayOfMonth ('2011-01-30')
--SELECT dbo.IGCF_GetLastDayOfMonth ('2011-02-05')

CREATE FUNCTION [dbo].[IGCF_GetLastDayOfMonth]
(
	@DATA DATE
)RETURNS DATE
AS
BEGIN
	DECLARE @ThisMonthFirstDay as DATE = CONVERT(VARCHAR(8), @DATA, 120) + '01'
	DECLARE @NextMonthFirstDay as DATE = DATEADD(MONTH, 1, @ThisMonthFirstDay)
	RETURN DATEADD(DAY, -1, @NextMonthFirstDay) 
END

GO
