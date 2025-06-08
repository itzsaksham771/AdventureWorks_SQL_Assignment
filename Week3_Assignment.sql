-- Task 1: Group tasks into projects and sort by duration and start date
CREATE TABLE Project (
    Task_ID INT PRIMARY KEY,
    Start_Date DATE,
    End_Date DATE
);

INSERT INTO Project (Task_ID, Start_Date, End_Date) VALUES
(1, '2015-10-01', '2015-10-02'),
(2, '2015-10-02', '2015-10-03'),
(3, '2015-10-03', '2015-10-04'),
(4, '2015-10-13', '2015-10-14'),
(5, '2015-10-14', '2015-10-15'),
(6, '2015-10-28', '2015-10-29'),
(7, '2015-10-30', '2015-10-31');


WITH TaskGroups AS (
  SELECT *,
         DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY Start_Date), Start_Date) AS group_key
  FROM Project
),
ProjectsGrouped AS (
  SELECT 
    MIN(Start_Date) AS Project_Start,
    MAX(End_Date) AS Project_End,
    DATEDIFF(DAY, MIN(Start_Date), MAX(End_Date)) + 1 AS Duration
  FROM TaskGroups
  GROUP BY group_key
)
SELECT 
  Project_Start,
  Project_End
FROM ProjectsGrouped
ORDER BY Duration, Project_Start;


-- Task 2

CREATE TABLE Students (
    ID INT PRIMARY KEY,
    Name VARCHAR(50)
);

CREATE TABLE Friends (
    ID INT PRIMARY KEY,
    Friend_ID INT
);

CREATE TABLE Packages (
    ID INT PRIMARY KEY,
    Salary FLOAT
);


INSERT INTO Students (ID, Name) VALUES
(1, 'Ashley'),
(2, 'Samantha'),
(3, 'Julia'),
(4, 'Scarlet');

INSERT INTO Friends (ID, Friend_ID) VALUES
(1, 2),
(2, 3),
(3, 4),
(4, 1);

INSERT INTO Packages (ID, Salary) VALUES
(1, 15.20),
(2, 10.06),
(3, 11.55),
(4, 12.12);

SELECT S.Name
FROM Students S
JOIN Friends F ON S.ID = F.ID
JOIN Packages SP ON S.ID = SP.ID
JOIN Packages FP ON F.Friend_ID = FP.ID
WHERE FP.Salary > SP.Salary
ORDER BY FP.Salary;

-- Task 3

-- Table Creation
CREATE TABLE Functions (
    X INT,
    Y INT
);

-- Sample Data
INSERT INTO Functions (X, Y) VALUES
(20, 20),
(20, 20),
(20, 21),
(23, 22),
(22, 23),
(21, 20);

-- Query to find symmetric pairs
SELECT DISTINCT f1.X, f1.Y
FROM Functions f1
JOIN Functions f2
    ON f1.X = f2.Y AND f1.Y = f2.X
WHERE f1.X <= f1.Y
ORDER BY f1.X;


--Task 4

DROP TABLE IF EXISTS Submission_Stats;
DROP TABLE IF EXISTS View_Stats;
DROP TABLE IF EXISTS Challenges;
DROP TABLE IF EXISTS Colleges;
DROP TABLE IF EXISTS Contests;


-- Create tables
CREATE TABLE Contests (
    contest_id INT,
    hacker_id INT,
    name VARCHAR(50)
);

CREATE TABLE Colleges (
    college_id INT,
    contest_id INT
);

CREATE TABLE Challenges (
    challenge_id INT,
    college_id INT
);

CREATE TABLE View_Stats (
    challenge_id INT,
    total_views INT,
    total_unique_views INT
);

CREATE TABLE Submission_Stats (
    challenge_id INT,
    total_submissions INT,
    total_accepted_submissions INT
);

-- Insert sample data from image
-- Insert into Contests
INSERT INTO Contests (contest_id, hacker_id, name) VALUES
(66406, 17973, 'Rose'),
(66556, 79153, 'Angela'),
(94828, 80275, 'Frank');

-- Insert into Colleges
INSERT INTO Colleges (college_id, contest_id) VALUES
(11219, 66406),
(32473, 66556),
(56865, 94828);

-- Insert into Challenges
INSERT INTO Challenges (challenge_id, college_id) VALUES
(18765, 11219),
(47127, 11219),
(60928, 32473),
(72974, 56865),
(73516, 56865);

-- Insert into View_Stats
INSERT INTO View_Stats (challenge_id, total_views, total_unique_views) VALUES
(47127, 26, 19),
(47127, 15, 14),
(18765, 43, 13),
(18765, 72, 13),
(73516, 35, 17),
(60928, 11, 10),
(72974, 41, 15),
(73516, 75, 11);

-- Insert into Submission_Stats
INSERT INTO Submission_Stats (challenge_id, total_submissions, total_accepted_submissions) VALUES
(73516, 24, 12),
(47127, 27, 10),
(47127, 56, 19),
(73516, 74, 12),
(72974, 68, 24),
(60928, 22, 11),
(47127, 28, 11);


-- Final Query
SELECT 
    c.contest_id,
    c.hacker_id,
    c.name,
    SUM(COALESCE(ss.total_submissions, 0)) AS total_submissions,
    SUM(COALESCE(ss.total_accepted_submissions, 0)) AS total_accepted_submissions,
    SUM(COALESCE(vs.total_views, 0)) AS total_views,
    SUM(COALESCE(vs.total_unique_views, 0)) AS total_unique_views
FROM Contests c
JOIN Colleges col ON c.contest_id = col.contest_id
JOIN Challenges ch ON ch.college_id = col.college_id
LEFT JOIN Submission_Stats ss ON ss.challenge_id = ch.challenge_id
LEFT JOIN View_Stats vs ON vs.challenge_id = ch.challenge_id
GROUP BY c.contest_id, c.hacker_id, c.name
HAVING 
    SUM(COALESCE(ss.total_submissions, 0)) > 0 OR
    SUM(COALESCE(ss.total_accepted_submissions, 0)) > 0 OR
    SUM(COALESCE(vs.total_views, 0)) > 0 OR
    SUM(COALESCE(vs.total_unique_views, 0)) > 0
ORDER BY c.contest_id;

-- TASK 5

CREATE TABLE Hackers (
    hacker_id INT,
    name VARCHAR(50)
);

CREATE TABLE Submissions (
    submission_date DATE,
    submission_id INT,
    hacker_id INT,
    score INT
);

-- Hackers Table
INSERT INTO Hackers VALUES (15758, 'Rose');
INSERT INTO Hackers VALUES (20703, 'Angela');
INSERT INTO Hackers VALUES (36396, 'Frank');
INSERT INTO Hackers VALUES (38289, 'Patrick');
INSERT INTO Hackers VALUES (44065, 'Lisa');
INSERT INTO Hackers VALUES (53473, 'Kimberly');
INSERT INTO Hackers VALUES (65289, 'Bonnie');
INSERT INTO Hackers VALUES (79722, 'Michael');

-- Submissions Table
INSERT INTO Submissions VALUES ('2016-03-01', 8494, 20703, 0);
INSERT INTO Submissions VALUES ('2016-03-01', 22403, 53473, 15);
INSERT INTO Submissions VALUES ('2016-03-01', 23965, 79722, 60);
INSERT INTO Submissions VALUES ('2016-03-01', 30173, 36396, 70);
INSERT INTO Submissions VALUES ('2016-03-02', 34928, 20703, 0);
INSERT INTO Submissions VALUES ('2016-03-02', 38740, 15758, 60);
INSERT INTO Submissions VALUES ('2016-03-02', 42769, 79722, 25);
INSERT INTO Submissions VALUES ('2016-03-02', 43484, 79722, 60);
INSERT INTO Submissions VALUES ('2016-03-03', 45440, 20703, 0);
INSERT INTO Submissions VALUES ('2016-03-03', 49050, 36396, 70);
INSERT INTO Submissions VALUES ('2016-03-03', 50273, 79722, 0);
INSERT INTO Submissions VALUES ('2016-03-04', 50364, 20703, 0);
INSERT INTO Submissions VALUES ('2016-03-04', 51308, 44065, 90);
INSERT INTO Submissions VALUES ('2016-03-04', 54404, 53473, 65);
INSERT INTO Submissions VALUES ('2016-03-04', 61533, 79722, 45);
INSERT INTO Submissions VALUES ('2016-03-05', 72852, 20703, 0);
INSERT INTO Submissions VALUES ('2016-03-05', 74548, 38289, 0);
INSERT INTO Submissions VALUES ('2016-03-05', 76487, 65289, 60);
INSERT INTO Submissions VALUES ('2016-03-05', 82439, 36396, 10);
INSERT INTO Submissions VALUES ('2016-03-06', 90006, 36396, 40);
INSERT INTO Submissions VALUES ('2016-03-06', 96044, 20703, 0);


WITH daily_counts AS (
    SELECT 
        submission_date,
        COUNT(DISTINCT hacker_id) AS total_hackers
    FROM Submissions
    GROUP BY submission_date
),
daily_max_hackers AS (
    SELECT 
        submission_date,
        hacker_id,
        COUNT(*) AS submissions_count
    FROM Submissions
    GROUP BY submission_date, hacker_id
),
ranked_hackers AS (
    SELECT 
        submission_date,
        hacker_id,
        submissions_count,
        RANK() OVER (
            PARTITION BY submission_date 
            ORDER BY submissions_count DESC, hacker_id ASC
        ) AS rnk
    FROM daily_max_hackers
)
SELECT 
    dc.submission_date,
    dc.total_hackers,
    rh.hacker_id,
    h.name
FROM daily_counts dc
JOIN ranked_hackers rh
    ON dc.submission_date = rh.submission_date
JOIN Hackers h
    ON rh.hacker_id = h.hacker_id
WHERE rh.rnk = 1
ORDER BY dc.submission_date;


 --    TASK 6 --
CREATE TABLE STATION (
    ID INT,
    CITY VARCHAR(21),
    STATE VARCHAR(2),
    LAT_N FLOAT,
    LONG_W FLOAT
);


INSERT INTO STATION (ID, CITY, STATE, LAT_N, LONG_W) VALUES
(1, 'New York', 'NY', 40.7128, 74.0060),
(2, 'Los Angeles', 'CA', 34.0522, 118.2437),
(3, 'Chicago', 'IL', 41.8781, 87.6298),
(4, 'Houston', 'TX', 29.7604, 95.3698),
(5, 'Phoenix', 'AZ', 33.4484, 112.0740),
(6, 'Philadelphia', 'PA', 39.9526, 75.1652);

SELECT 
    ROUND(
        ABS(MIN(LAT_N) - MAX(LAT_N)) + ABS(MIN(LONG_W) - MAX(LONG_W)),
        4
    ) AS ManhattanDistance
FROM STATION;



    -- TASK 7 --
-- Generate numbers from 2 to 1000 using a recursive CTE
WITH Numbers AS (
    SELECT 2 AS n
    UNION ALL
    SELECT n + 1 FROM Numbers WHERE n < 1000
),
-- Filter primes
Primes AS (
    SELECT n FROM Numbers AS outerN
    WHERE NOT EXISTS (
        SELECT 1 FROM Numbers AS innerN
        WHERE innerN.n < outerN.n AND outerN.n % innerN.n = 0
    )
)
-- Combine using FOR XML PATH
SELECT STUFF((
    SELECT '&' + CAST(n AS VARCHAR)
    FROM Primes
    ORDER BY n
    FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS PrimeNumbers
OPTION (MAXRECURSION 1000);


    -- TASK 8 --
DROP TABLE IF EXISTS OCCUPATIONS;

-- STEP 1: Create the table
CREATE TABLE OCCUPATIONS (
    Name VARCHAR(50),
    Occupation VARCHAR(20)
);

-- STEP 2: Insert sample data
INSERT INTO OCCUPATIONS (Name, Occupation) VALUES
('Samantha', 'Doctor'),
('Julia', 'Actor'),
('Maria', 'Actor'),
('Meera', 'Singer'),
('Ashely', 'Professor'),
('Ketty', 'Professor'),
('Christeen', 'Professor'),
('Jane', 'Actor'),
('Jenny', 'Doctor'),
('Priya', 'Singer');

-- STEP 3: Pivot-style output
WITH Ranked AS (
    SELECT 
        Name,
        Occupation,
        ROW_NUMBER() OVER (PARTITION BY Occupation ORDER BY Name) AS rn
    FROM OCCUPATIONS
)
SELECT
    MAX(CASE WHEN Occupation = 'Doctor' THEN Name END) AS Doctor,
    MAX(CASE WHEN Occupation = 'Professor' THEN Name END) AS Professor,
    MAX(CASE WHEN Occupation = 'Singer' THEN Name END) AS Singer,
    MAX(CASE WHEN Occupation = 'Actor' THEN Name END) AS Actor
FROM Ranked
GROUP BY rn
ORDER BY rn;


 -- TASK 9 --
 CREATE TABLE BST (
    N INTEGER,
    P INTEGER
);

INSERT INTO BST (N, P) VALUES
(1, 2),
(3, 2),
(6, 8),
(9, 8),
(2, 5),
(8, 5),
(5, NULL);


SELECT
    N,
    CASE
        WHEN P IS NULL THEN 'Root'
        WHEN N NOT IN (SELECT DISTINCT P FROM BST WHERE P IS NOT NULL) THEN 'Leaf'
        ELSE 'Inner'
    END AS NodeType
FROM BST
ORDER BY N;

        -- TASK 10 --
CREATE TABLE Company (
    company_code VARCHAR(10),
    founder VARCHAR(50)
);

CREATE TABLE Lead_Manager (
    lead_manager_code VARCHAR(10),
    company_code VARCHAR(10)
);

CREATE TABLE Senior_Manager (
    senior_manager_code VARCHAR(10),
    lead_manager_code VARCHAR(10),
    company_code VARCHAR(10)
);

CREATE TABLE Manager (
    manager_code VARCHAR(10),
    senior_manager_code VARCHAR(10),
    lead_manager_code VARCHAR(10),
    company_code VARCHAR(10)
);

CREATE TABLE Employee (
    employee_code VARCHAR(10),
    manager_code VARCHAR(10),
    senior_manager_code VARCHAR(10),
    lead_manager_code VARCHAR(10),
    company_code VARCHAR(10)
);


-- Company Table
INSERT INTO Company VALUES ('C1', 'Monika');
INSERT INTO Company VALUES ('C2', 'Samantha');

-- Lead_Manager Table
INSERT INTO Lead_Manager VALUES ('LM1', 'C1');
INSERT INTO Lead_Manager VALUES ('LM2', 'C2');

-- Senior_Manager Table
INSERT INTO Senior_Manager VALUES ('SM1', 'LM1', 'C1');
INSERT INTO Senior_Manager VALUES ('SM2', 'LM1', 'C1');
INSERT INTO Senior_Manager VALUES ('SM3', 'LM2', 'C2');

-- Manager Table
INSERT INTO Manager VALUES ('M1', 'SM1', 'LM1', 'C1');
INSERT INTO Manager VALUES ('M2', 'SM3', 'LM2', 'C2');
INSERT INTO Manager VALUES ('M3', 'SM3', 'LM2', 'C2');

-- Employee Table
INSERT INTO Employee VALUES ('E1', 'M1', 'SM1', 'LM1', 'C1');
INSERT INTO Employee VALUES ('E2', 'M1', 'SM1', 'LM1', 'C1');
INSERT INTO Employee VALUES ('E3', 'M2', 'SM3', 'LM2', 'C2');
INSERT INTO Employee VALUES ('E4', 'M3', 'SM3', 'LM2', 'C2');


SELECT
    c.company_code,
    c.founder,
    (SELECT COUNT(DISTINCT lead_manager_code) FROM Lead_Manager lm WHERE lm.company_code = c.company_code) AS lead_manager_count,
    (SELECT COUNT(DISTINCT senior_manager_code) FROM Senior_Manager sm WHERE sm.company_code = c.company_code) AS senior_manager_count,
    (SELECT COUNT(DISTINCT manager_code) FROM Manager m WHERE m.company_code = c.company_code) AS manager_count,
    (SELECT COUNT(DISTINCT employee_code) FROM Employee e WHERE e.company_code = c.company_code) AS employee_count
FROM Company c
ORDER BY c.company_code;

   -- TASK 11 --

   -- Drop tables if they already exist
DROP TABLE IF EXISTS Students;
DROP TABLE IF EXISTS Friends;
DROP TABLE IF EXISTS Packages;

-- Create Students table
CREATE TABLE Students (
    ID INTEGER,
    Name VARCHAR(50)
);

-- Insert data into Students
INSERT INTO Students (ID, Name) VALUES
(1, 'Ashley'),
(2, 'Samantha'),
(3, 'Julia'),
(4, 'Scarlet');

-- Create Friends table
CREATE TABLE Friends (
    ID INTEGER,
    Friend_ID INTEGER
);

-- Insert data into Friends
INSERT INTO Friends (ID, Friend_ID) VALUES
(1, 2),
(2, 3),
(3, 4),
(4, 1);

-- Create Packages table
CREATE TABLE Packages (
    ID INTEGER,
    Salary FLOAT
);

-- Insert data into Packages
INSERT INTO Packages (ID, Salary) VALUES
(1, 15.20),
(2, 10.06),
(3, 11.55),
(4, 12.12);

SELECT s.Name
FROM Students s
JOIN Friends f ON s.ID = f.ID
JOIN Packages p1 ON s.ID = p1.ID
JOIN Packages p2 ON f.Friend_ID = p2.ID
WHERE p1.Salary < p2.Salary
ORDER BY p2.Salary;

     --TASK 12 --
-- Calculate total cost by job family and location (India/International)
WITH JobFamilyCost AS (
    SELECT
        d.Name AS JobFamily,
        CASE 
            WHEN cr.Name = 'India' THEN 'India'
            ELSE 'International'
        END AS Region,
        SUM(eph.Rate) AS TotalCost
    FROM HumanResources.Employee e
    INNER JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
    INNER JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
    INNER JOIN HumanResources.EmployeePayHistory eph ON e.BusinessEntityID = eph.BusinessEntityID
    INNER JOIN Person.BusinessEntityAddress bea ON e.BusinessEntityID = bea.BusinessEntityID
    INNER JOIN Person.Address a ON bea.AddressID = a.AddressID
    INNER JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
    INNER JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
    GROUP BY d.Name, cr.Name
)
, JobFamilyTotal AS (
    SELECT
        JobFamily,
        SUM(TotalCost) AS FamilyTotal
    FROM JobFamilyCost
    GROUP BY JobFamily
)
SELECT
    jfc.JobFamily,
    jfc.Region,
    jfc.TotalCost,
    ROUND(100.0 * jfc.TotalCost / jft.FamilyTotal, 2) AS PercentageOfTotal
FROM JobFamilyCost jfc
JOIN JobFamilyTotal jft ON jfc.JobFamily = jft.JobFamily
ORDER BY jfc.JobFamily, jfc.Region;


  -- TASK 13 find ratio of cost and revenue of a BU month on month --
  -- Step 1: Calculate monthly revenue by Sales Territory
WITH MonthlyRevenue AS (
    SELECT
        st.Name AS BusinessUnit,
        YEAR(soh.OrderDate) AS Year,
        MONTH(soh.OrderDate) AS Month,
        SUM(soh.TotalDue) AS Revenue
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
    GROUP BY st.Name, YEAR(soh.OrderDate), MONTH(soh.OrderDate)
),
-- Step 2: Calculate monthly cost by Sales Territory (approximate, as cost is at product level)
MonthlyCost AS (
    SELECT
        st.Name AS BusinessUnit,
        YEAR(soh.OrderDate) AS Year,
        MONTH(soh.OrderDate) AS Month,
        SUM(sod.OrderQty * p.StandardCost) AS Cost
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    JOIN Production.Product p ON sod.ProductID = p.ProductID
    JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
    GROUP BY st.Name, YEAR(soh.OrderDate), MONTH(soh.OrderDate)
)
-- Step 3: Join and calculate ratio
SELECT
    mr.BusinessUnit,
    mr.Year,
    mr.Month,
    mr.Revenue,
    mc.Cost,
    CASE
        WHEN mr.Revenue = 0 THEN NULL
        ELSE mc.Cost / mr.Revenue
    END AS CostToRevenueRatio
FROM MonthlyRevenue mr
JOIN MonthlyCost mc ON mr.BusinessUnit = mc.BusinessUnit AND mr.Year = mc.Year AND mr.Month = mc.Month
ORDER BY mr.BusinessUnit, mr.Year, mr.Month;

	  -- TASK 14 --
-- Get headcount by OrganizationLevel (as SubBand)
SELECT 
    OrganizationLevel AS SubBand,
    COUNT(*) AS Headcount
FROM HumanResources.Employee
GROUP BY OrganizationLevel;

-- Get total headcount (for manual percentage calculation)
SELECT COUNT(*) AS TotalHeadcount FROM HumanResources.Employee;

  -- TASK 15 --
  SELECT TOP 5 e.BusinessEntityID, e.JobTitle, eph.Rate AS Salary
FROM HumanResources.Employee e
JOIN HumanResources.EmployeePayHistory eph ON e.BusinessEntityID = eph.BusinessEntityID;

-- TASK 16 --

CREATE TABLE TableA (ID INT, Col1 VARCHAR(10), Col2 VARCHAR(10));
CREATE TABLE TableB (ID INT, Col1 VARCHAR(10), Col2 VARCHAR(10));

-- Step 2: Data insertion
INSERT INTO TableA VALUES (1, 'A', 'X');
INSERT INTO TableB VALUES (2, 'B', 'Y');

UPDATE TableA
SET Col1 = Col2, Col2 = Col1
WHERE ID = 1;


UPDATE TableB
SET Col1 = Col2, Col2 = Col1
WHERE ID = 2;


SELECT * FROM TableA;
SELECT * FROM TableB;

   --TASK 17--
-- 1. Create a login
CREATE LOGIN MyUserLogin WITH PASSWORD = 'YourSecurePassword123!';

-- 2. Create a user for the login in your database
USE AdventureWorks2022;
CREATE USER MyUser FOR LOGIN MyUserLogin;

-- 3. Add user to the db_owner role
ALTER ROLE db_owner ADD MEMBER MyUser;


 -- TASK 18 --
 -- Example: Using Department as BU
WITH EmployeePayPeriods AS (
    SELECT
        d.Name AS BusinessUnit,
        YEAR(eph.RateChangeDate) AS Year,
        MONTH(eph.RateChangeDate) AS Month,
        eph.Rate,
        DATEDIFF(DAY, 
            eph.RateChangeDate, 
            ISNULL(LEAD(eph.RateChangeDate) OVER (PARTITION BY eph.BusinessEntityID ORDER BY eph.RateChangeDate), GETDATE())
        ) AS DaysActive
    FROM HumanResources.EmployeePayHistory eph
    JOIN HumanResources.EmployeeDepartmentHistory edh 
        ON eph.BusinessEntityID = edh.BusinessEntityID
        AND edh.EndDate IS NULL
    JOIN HumanResources.Department d 
        ON edh.DepartmentID = d.DepartmentID
)
SELECT
    BusinessUnit,
    Year,
    Month,
    SUM(Rate * DaysActive) / SUM(DaysActive) AS WeightedAvgCost
FROM EmployeePayPeriods
WHERE DaysActive > 0
GROUP BY BusinessUnit, Year, Month
ORDER BY BusinessUnit, Year, Month;



    -- TASK 19 --

CREATE TABLE EMPLOYEES (
    id INT,
    salary DECIMAL(10, 2)
);
INSERT INTO EMPLOYEES VALUES (1, 10050);
INSERT INTO EMPLOYEES VALUES (2, 2000);
INSERT INTO EMPLOYEES VALUES (3, 3050);
INSERT INTO EMPLOYEES VALUES (4, 4000);
INSERT INTO EMPLOYEES VALUES (5, 5000);

WITH Actual AS (
    SELECT AVG(salary) AS actual_avg
    FROM EMPLOYEES
),
Miscalculated AS (
    SELECT AVG(CAST(
        REPLACE(
            REPLACE(
                REPLACE(
                    CAST(salary AS VARCHAR),
                    '0', ''
                ),
                '0', ''
            ),
            '0', ''
        ) AS DECIMAL
    )) AS miscalculated_avg
    FROM EMPLOYEES
)
SELECT CEILING(actual_avg - miscalculated_avg) AS error_amount
FROM Actual, Miscalculated;


 -- TASK 20 --
 -- Step 1: Create sample tables
CREATE TABLE SourceTable (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    salary DECIMAL(10, 2)
);
CREATE TABLE DestinationTable (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    salary DECIMAL(10, 2)
);
-- Insert some sample data
INSERT INTO SourceTable VALUES (1, 'Alice', 5000);
INSERT INTO SourceTable VALUES (2, 'Bob', 6000);
INSERT INTO SourceTable VALUES (3, 'Charlie', 7000);
INSERT INTO DestinationTable VALUES (1, 'Alice', 5000); -- This row already exists in DestinationTable


-- Step 2: Copy only new data (no duplicates)
INSERT INTO DestinationTable
SELECT s.*
FROM SourceTable s
LEFT JOIN DestinationTable d ON s.id = d.id
WHERE d.id IS NULL;

