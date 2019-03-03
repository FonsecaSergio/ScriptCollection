IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TimeInSeconds]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[TimeInSeconds]
GO
----------------------------------------------------------------------------------------
/*
	SELECT [dbo].[TimeInSeconds] (60)
*/
----------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[TimeInSeconds]
(
	@seconds as int
)
RETURNS VARCHAR(100)
BEGIN
	RETURN LEFT(CONVERT(VARCHAR(100), @seconds) + 's',100)
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TimeInMinutes]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[TimeInMinutes]
GO
----------------------------------------------------------------------------------------
/*
	SELECT [dbo].[TimeInMinutes (62)
*/
----------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[TimeInMinutes]
(
	@seconds as int
)
RETURNS VARCHAR(100)
BEGIN
	RETURN LEFT(CONVERT(VARCHAR(100), FLOOR(@seconds / 60)) + 'm ' + [dbo].[TimeInSeconds](@seconds % 60), 100) 
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TimeInHours]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[TimeInHours]
GO
----------------------------------------------------------------------------------------
/*
	SELECT [dbo].[TimeInHours] (4884)
*/
----------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[TimeInHours]
(
	@seconds as int
)
RETURNS VARCHAR(100)
BEGIN
	RETURN LEFT(CONVERT(VARCHAR(100), FLOOR(@seconds / 3600)) + 'h ' + [dbo].[TimeInMinutes](@seconds % 3600), 100) 
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TimeInDays]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[TimeInDays]
GO
----------------------------------------------------------------------------------------
/*
	SELECT [dbo].[TimeInDays] (100000)
*/
----------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[TimeInDays]
(
	@seconds as int
)
RETURNS VARCHAR(100)
BEGIN
	RETURN LEFT(CONVERT(VARCHAR(100), FLOOR(@seconds / 86400)) + 'd ' + [dbo].[TimeInHours](@seconds % 86400), 100) 
END
GO



IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnTimeInWords]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnTimeInWords]
GO


----------------------------------------------------------------------------------------
/*
	SELECT [dbo].[TimeInSeconds] (60)
	SELECT [dbo].[TimeInMinutes] (62)
	SELECT [dbo].[TimeInHours]   (4884)
	SELECT [dbo].[TimeInDays]    (100000)
	
	SELECT [dbo].[fnTimeInWords] (60)
	SELECT [dbo].[fnTimeInWords] (62)
	SELECT [dbo].[fnTimeInWords] (4884)
	SELECT [dbo].[fnTimeInWords] (100000)

*/
----------------------------------------------------------------------------------------


CREATE FUNCTION [dbo].[fnTimeInWords]
(
	@seconds as int
)
RETURNS VARCHAR(100)
AS
BEGIN
    DECLARE @ReturnValue As VARCHAR(100)
    
    IF (@seconds > 86400) 
        SET @ReturnValue = [dbo].[TimeInDays](@seconds) 
    ELSE IF (@seconds > 3600) 
        SET @ReturnValue = [dbo].[TimeInHours](@seconds) 
    ELSE IF (@seconds > 60) 
        SET @ReturnValue = [dbo].[TimeInMinutes](@seconds) 
    ELSE 
        SET @ReturnValue = [dbo].[TimeInSeconds](@seconds)
    
    
    RETURN @ReturnValue 

END
