
/*
Factorial Function

Create a scalar-valued function that returns the factorial of a number you gave it.
*/

CREATE PROCEDURE factorial @n INT
AS
BEGIN
    DECLARE @result BIGINT = 1;
    DECLARE @i INT = 1;

    IF @n < 0
    BEGIN
        -- Negative number error handling
        PRINT 'Factorial is not defined for negative numbers.';
        RETURN;
    END

    WHILE @i <= @n
    BEGIN
        SET @result = @result * @i;
        SET @i = @i + 1;
    END

    PRINT 'Factorial of ' + CAST(@n AS NVARCHAR(10)) + ' is ' + CAST(@result AS NVARCHAR(20));
END;



EXEC factorial @n = 5;

EXEC factorial @n = -4;

EXEC factorial @n = 0;



-----

CREATE FUNCTION CalculateFactorial(@n INT)
RETURNS INT
AS
BEGIN
    DECLARE @result INT

    IF @n <= 1
        SET @result = 1
    ELSE
        SET @result = @n * dbo.CalculateFactorial(@n - 1)

    RETURN @result
END
GO

SELECT dbo.CalculateFactorial(5) AS FactorialOf5;




