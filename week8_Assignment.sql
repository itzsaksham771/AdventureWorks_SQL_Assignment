CREATE PROCEDURE PopulateTimeDimension
    @InputDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    ;WITH DatesCTE AS (
        SELECT @StartDate AS DateValue
        UNION ALL
        SELECT DATEADD(DAY, 1, DateValue)
        FROM DatesCTE
        WHERE DateValue < @EndDate
    )

    INSERT INTO TimeDimension (
        [Date],
        CalendarDayNumber,
        CalendarWeek,
        CalendarMonth,
        CalendarQuarter,
        CalendarYear,
        DayName,
        DayShortName,
        DayOfWeek,
        DaySuffix,
        MonthName,
        FiscalYear,
        FiscalPeriod,
        FiscalWeek,
        FiscalYearPeriod
    )
    SELECT
        DateValue,
        DATEPART(DAYOFYEAR, DateValue),
        DATEPART(WEEK, DateValue),
        DATEPART(MONTH, DateValue),
        DATEPART(QUARTER, DateValue),
        DATEPART(YEAR, DateValue),
        DATENAME(WEEKDAY, DateValue),
        LEFT(DATENAME(WEEKDAY, DateValue), 3),
        DATEPART(WEEKDAY, DateValue),
        CAST(DAY(DateValue) AS VARCHAR) +
            CASE 
                WHEN DAY(DateValue) IN (11,12,13) THEN 'th'
                WHEN RIGHT(CAST(DAY(DateValue) AS VARCHAR),1) = '1' THEN 'st'
                WHEN RIGHT(CAST(DAY(DateValue) AS VARCHAR),1) = '2' THEN 'nd'
                WHEN RIGHT(CAST(DAY(DateValue) AS VARCHAR),1) = '3' THEN 'rd'
                ELSE 'th'
            END,
        DATENAME(MONTH, DateValue),
        DATEPART(YEAR, DateValue), -- FiscalYear same as CalendarYear (adjust if needed)
        DATEPART(MONTH, DateValue), -- FiscalPeriod same as CalendarMonth (adjust if needed)
        DATEPART(WEEK, DateValue), -- FiscalWeek same as CalendarWeek (adjust if needed)
        CAST(DATEPART(YEAR, DateValue) AS VARCHAR) + RIGHT('0' + CAST(DATEPART(MONTH, DateValue) AS VARCHAR), 2)
    FROM DatesCTE
    OPTION (MAXRECURSION 366);
END



CREATE TABLE TimeDimension (
    [Date] DATE PRIMARY KEY,
    CalendarDayNumber INT,
    CalendarWeek INT,
    CalendarMonth INT,
    CalendarQuarter INT,
    CalendarYear INT,
    DayName VARCHAR(20),
    DayShortName VARCHAR(10),
    DayOfWeek INT,
    DaySuffix VARCHAR(5),
    MonthName VARCHAR(20),
    FiscalYear INT,
    FiscalPeriod INT,
    FiscalWeek INT,
    FiscalYearPeriod VARCHAR(10)
);


EXEC PopulateTimeDimension '2020-07-14';


SELECT * FROM TimeDimension
WHERE CalendarYear = 2020;

