-- Source: https://www.mytecbits.com/microsoft/sql-server/extract-numbers-from-string

CREATE FUNCTION [dbo].[mtb_GetNumbers] 
(
    @stInput VARCHAR(max)
)
RETURNS VARCHAR(max)
AS
BEGIN
 
    SET @stInput = REPLACE(@stInput,',','')
     
    DECLARE @intAlpha INT
    DECLARE @intNumber INT
 
    SET @intAlpha = PATINDEX('%[^0-9,]%', @stInput)
    SET @intNumber = PATINDEX('%[0-9,]%', @stInput)
 
    IF @stInput IS NULL OR @intNumber = 0
        RETURN '';
 
    WHILE @intAlpha > 0 
    BEGIN
        IF (@intAlpha > @intNumber)
        BEGIN
            SET @intNumber = PATINDEX('%[0-9,]%', SUBSTRING(@stInput, @intAlpha, LEN(@stInput)) )
            SELECT @intNumber = CASE WHEN @intNumber = 0 THEN LEN(@stInput) ELSE @intNumber END
        END
 
        SET @stInput = STUFF(@stInput, @intAlpha, @intNumber - 1,',' );
             
        SET @intAlpha = PATINDEX('%[^0-9,]%', @stInput )
        SET @intNumber = PATINDEX('%[0-9,]%', SUBSTRING(@stInput, @intAlpha, LEN(@stInput)) )
        SELECT @intNumber = CASE WHEN @intNumber = 0 THEN LEN(@stInput) ELSE @intNumber END
    END
     
 
    IF (RIGHT(@stInput, 1) = ',')
        SET @stInput = LEFT(@stInput, LEN(@stInput) - 1)
 
    IF (LEFT(@stInput, 1) = ',')
        SET @stInput = RIGHT(@stInput, LEN(@stInput) - 1)
 
    RETURN ISNULL(@stInput,0)
END
GO