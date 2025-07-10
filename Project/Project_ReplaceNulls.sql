CREATE TABLE HZL_Table (
    [Date] DATE,
    BU VARCHAR(10),
    Value INT
);

INSERT INTO HZL_Table ([Date], BU, Value)
VALUES 
('2024-01-01', 'hzl', 3456),
('2024-02-01', 'hzl', NULL),
('2024-03-01', 'hzl', NULL),
('2024-04-01', 'hzl', NULL),
('2024-01-01', 'SC' , 32456),
('2024-02-01', 'SC' , NULL),
('2024-03-01', 'SC' , NULL),
('2024-04-01', 'SC' , NULL),
('2024-05-01', 'SC' , 345),
('2024-06-01', 'SC' , NULL);


Select * from HZL_Table;


SELECT 
    H.Date,
    H.BU,
    ISNULL(H.Value, Prev.Value) AS Value
FROM 
    HZL_Table H
OUTER APPLY (
    SELECT TOP 1 Value
    FROM HZL_Table H2
    WHERE 
        H2.BU = H.BU 
        AND H2.Date <= H.Date 
        AND H2.Value IS NOT NULL
    ORDER BY H2.Date DESC
) AS Prev
ORDER BY 
    H.BU, H.Date;


-- Use a CTE to identify the correct values to update
WITH UpdatedValues AS (
    SELECT 
        H.Date,
        H.BU,
        H.Value AS OriginalValue,
        ISNULL(H.Value, Prev.Value) AS NewValue
    FROM 
        HZL_Table H
    OUTER APPLY (
        SELECT TOP 1 Value
        FROM HZL_Table H2
        WHERE 
            H2.BU = H.BU 
            AND H2.Date <= H.Date 
            AND H2.Value IS NOT NULL
        ORDER BY H2.Date DESC
    ) AS Prev
)
UPDATE HZL_Table
SET Value = U.NewValue
FROM HZL_Table H
JOIN UpdatedValues U
    ON H.Date = U.Date AND H.BU = U.BU
WHERE H.Value IS NULL;



Select * from HZL_Table;
