USE AdventureWorks2022;
GO

DROP PROCEDURE IF EXISTS InsertOrderDetails;
GO


CREATE PROCEDURE InsertOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity INT,
    @Discount FLOAT = NULL
AS
BEGIN
    DECLARE @ActualUnitPrice MONEY
    DECLARE @ActualDiscount FLOAT
    DECLARE @Stock INT
    DECLARE @ReorderLevel INT

    -- Get UnitPrice from Products table if not provided
    IF @UnitPrice IS NULL
        SELECT @ActualUnitPrice = ListPrice 
        FROM Production.Product 
        WHERE ProductID = @ProductID
    ELSE
        SET @ActualUnitPrice = @UnitPrice

    -- Set Discount to 0 if not provided
    IF @Discount IS NULL
        SET @ActualDiscount = 0
    ELSE
        SET @ActualDiscount = @Discount

    -- Get current stock and reorder level
    SELECT @Stock = pi.Quantity, @ReorderLevel = p.SafetyStockLevel 
    FROM Production.ProductInventory pi
    JOIN Production.Product p ON pi.ProductID = p.ProductID
    WHERE pi.ProductID = @ProductID

    -- Check stock availability
    IF @Stock IS NULL OR @Stock < @Quantity
    BEGIN
        PRINT 'Failed to place the order. Please try again.'
        RETURN
    END

    -- Insert the order
    INSERT INTO Sales.SalesOrderDetail (SalesOrderID, ProductID, OrderQty, UnitPrice, UnitPriceDiscount)
    VALUES (@OrderID, @ProductID, @Quantity, @ActualUnitPrice, @ActualDiscount)

    -- Check if insert succeeded
    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'Failed to place the order. Please try again.'
        RETURN
    END

    -- Reduce stock
    UPDATE Production.ProductInventory
    SET Quantity = Quantity - @Quantity
    WHERE ProductID = @ProductID

    -- Check and notify if stock is below reorder level
    SELECT @Stock = pi.Quantity 
    FROM Production.ProductInventory pi
    WHERE pi.ProductID = @ProductID

    IF @Stock < @ReorderLevel
    BEGIN
        PRINT 'Warning: Stock of the product has dropped below its Reorder Level.'
    END
END


-- Q2

DROP PROCEDURE IF EXISTS UpdateOrderDetails;
GO

CREATE PROCEDURE UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity INT = NULL,
    @Discount FLOAT = NULL
AS
BEGIN
    DECLARE @OldQuantity INT
    DECLARE @NewQuantity INT
    DECLARE @QtyDiff INT

    -- Get current quantity
    SELECT @OldQuantity = OrderQty
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID

    IF @OldQuantity IS NULL
    BEGIN
        PRINT 'No matching order details found.'
        RETURN
    END

    -- Use ISNULL to retain existing values if NULL passed
    UPDATE Sales.SalesOrderDetail
    SET 
        UnitPrice = ISNULL(@UnitPrice, UnitPrice),
        OrderQty = ISNULL(@Quantity, OrderQty),
        UnitPriceDiscount = ISNULL(@Discount, UnitPriceDiscount)
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID

    -- Update stock in ProductInventory (adjust UnitsInStock based on quantity change)
    SET @NewQuantity = ISNULL(@Quantity, @OldQuantity)
    SET @QtyDiff = @NewQuantity - @OldQuantity

    UPDATE Production.ProductInventory
    SET Quantity = Quantity - @QtyDiff
    WHERE ProductID = @ProductID
END


--Q3

DROP PROCEDURE IF EXISTS GetOrderDetails;
GO

CREATE PROCEDURE GetOrderDetails
    @OrderID INT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID
    )
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist';
        RETURN 1;
    END

    SELECT *
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID;
END


EXEC GetOrderDetails @OrderID = 43659; ---- Existing order (replace with actual valid OrderID)

-- Q4

DROP PROCEDURE IF EXISTS DeleteOrderDetails;
GO

CREATE PROCEDURE DeleteOrderDetails
    @OrderID INT,
    @ProductID INT
AS
BEGIN
    DECLARE @DeletedQty INT

    -- Check existence and get current quantity
    SELECT @DeletedQty = OrderQty
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID

    IF @DeletedQty IS NULL
    BEGIN
        PRINT 'Error: No matching order details found for OrderID ' + 
              CAST(@OrderID AS VARCHAR) + ' and ProductID ' + 
              CAST(@ProductID AS VARCHAR) + '.'
        RETURN
    END

    -- Delete the order detail
    DELETE FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID

    -- Restore stock to inventory
    UPDATE Production.ProductInventory
    SET Quantity = Quantity + @DeletedQty
    WHERE ProductID = @ProductID

    PRINT 'Successfully deleted order detail and updated inventory.'
END
GO
--Sample record delete
EXEC DeleteOrderDetails @OrderID = 43659, @ProductID = 776

-- Q5 Create a function that takes an input parameter type datetime and returns the date in.............
DROP FUNCTION IF EXISTS dbo.FormatDateMMDDYYYY;
GO

CREATE FUNCTION dbo.FormatDateMMDDYYYY
(
    @InputDate DATETIME
)
RETURNS VARCHAR(10)
AS
BEGIN
    -- Convert to MM/DD/YYYY format using CONVERT with style 101
    RETURN CONVERT(VARCHAR(10), @InputDate, 101)
END
GO

--Q6 Create a function that takes an input parameter type datetime and returns the date in the format YYYYMMDD
DROP FUNCTION IF EXISTS dbo.FormatDateYYYYMMDD;
GO

CREATE FUNCTION dbo.FormatDateYYYYMMDD
(
    @InputDate DATETIME
)
RETURNS VARCHAR(8)
AS
BEGIN
    -- Convert to YYYYMMDD format using CONVERT with style 112
    RETURN CONVERT(VARCHAR(8), @InputDate, 112)
END
GO
--Example
--SELECT dbo.FormatDateYYYYMMDD('2006-11-21 23:34:05.920') AS FormattedDate;

--Views
--Q7
DROP VIEW IF EXISTS vwCustomerOrders;
GO

CREATE VIEW vwCustomerOrders AS
SELECT
    s.Name AS CompanyName,
    soh.SalesOrderID AS OrderID,
    soh.OrderDate,
    sod.ProductID,
    p.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    (sod.OrderQty * sod.UnitPrice) AS TotalPrice
FROM
    Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesOrderDetail AS sod
        ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN Sales.Customer AS c
        ON soh.CustomerID = c.CustomerID
    INNER JOIN Sales.Store AS s
        ON c.StoreID = s.BusinessEntityID
    INNER JOIN Production.Product AS p
        ON sod.ProductID = p.ProductID
WHERE
    c.StoreID IS NOT NULL  -- Only store customers have a company name
;
GO

--Q8 Create a copy of the above view and modify it so that it only returns the above information for orders that were placed yesterday
DROP VIEW IF EXISTS vwCustomerOrders_Yesterday;
GO

CREATE VIEW vwCustomerOrders_Yesterday AS
SELECT
    COALESCE(s.Name, p.LastName + ', ' + p.FirstName) AS CompanyName,
    soh.SalesOrderID AS OrderID,
    soh.OrderDate,
    sod.ProductID,
    pr.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    (sod.OrderQty * sod.UnitPrice) AS TotalPrice
FROM
    Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesOrderDetail AS sod
        ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN Sales.Customer AS c
        ON soh.CustomerID = c.CustomerID
    LEFT JOIN Sales.Store AS s
        ON c.StoreID = s.BusinessEntityID
    LEFT JOIN Person.Person AS p
        ON c.PersonID = p.BusinessEntityID
    INNER JOIN Production.Product AS pr
        ON sod.ProductID = pr.ProductID
WHERE
    CAST(soh.OrderDate AS DATE) = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
;
GO


--Q9 
DROP VIEW IF EXISTS MyProducts;
GO

CREATE VIEW MyProducts AS
SELECT
    p.ProductID,
    p.Name AS ProductName,
    p.ProductNumber AS QuantityPerUnit, -- No direct equivalent, so using ProductNumber
    p.ListPrice AS UnitPrice,
    s.Name AS CompanyName,
    c.Name AS CategoryName
FROM
    Production.Product p
    INNER JOIN Purchasing.ProductVendor pv ON p.ProductID = pv.ProductID
    INNER JOIN Purchasing.Vendor s ON pv.BusinessEntityID = s.BusinessEntityID
    INNER JOIN Production.ProductSubcategory c ON p.ProductSubcategoryID = c.ProductSubcategoryID
WHERE
    p.DiscontinuedDate IS NULL -- Only products not discontinued
;
GO

--Q10 Question on trigger
-- firstly creating sample data
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    OrderDate DATETIME
);

CREATE TABLE [Order Details] (
    OrderDetailID INT PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);
INSERT INTO Orders (OrderID, OrderDate) VALUES (1, '2024-06-01');
INSERT INTO Orders (OrderID, OrderDate) VALUES (2, '2024-06-02');

INSERT INTO [Order Details] (OrderDetailID, OrderID, ProductID) VALUES (101, 1, 1001);
INSERT INTO [Order Details] (OrderDetailID, OrderID, ProductID) VALUES (102, 1, 1002);
INSERT INTO [Order Details] (OrderDetailID, OrderID, ProductID) VALUES (103, 2, 1003);

--Trigger
DROP TRIGGER IF EXISTS trg_InsteadOfDeleteOrder ON Orders;
GO

CREATE TRIGGER trg_InsteadOfDeleteOrder
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    -- Delete related order details first
    DELETE FROM [Order Details]
    WHERE OrderID IN (SELECT OrderID FROM DELETED);

    -- Now delete the order(s)
    DELETE FROM Orders
    WHERE OrderID IN (SELECT OrderID FROM DELETED);
END
GO

--Testing trigger
SELECT * FROM Orders;
SELECT * FROM [Order Details];

DELETE FROM Orders WHERE OrderID = 1;

SELECT * FROM Orders;
SELECT * FROM [Order Details];
--Successfully Done

--Q11

--firstly create tables
DROP TABLE IF EXISTS [Order Details];
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Products;

CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50),
    UnitsInStock INT
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    OrderDate DATETIME
);

CREATE TABLE [Order Details] (
    OrderDetailID INT PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);


--Sample Data
INSERT INTO Products (ProductID, ProductName, UnitsInStock) VALUES (1, 'Pen', 20);
INSERT INTO Products (ProductID, ProductName, UnitsInStock) VALUES (2, 'Pencil', 10);

INSERT INTO Orders (OrderID, OrderDate) VALUES (1, '2024-06-01');
INSERT INTO Orders (OrderID, OrderDate) VALUES (2, '2024-06-02');

--Create the INSTEAD OF INSERT Trigger
-- Drop trigger if it exists
IF OBJECT_ID(N'[dbo].[trg_InsertOrderDetails_CheckStock]', N'TR') IS NOT NULL
    DROP TRIGGER [dbo].[trg_InsertOrderDetails_CheckStock];
GO

CREATE TRIGGER [dbo].[trg_InsertOrderDetails_CheckStock]
ON [dbo].[Order Details]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check for insufficient stock
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Products p ON i.ProductID = p.ProductID
        WHERE i.Quantity > p.UnitsInStock
    )
    BEGIN
        RAISERROR ('Order could not be filled because of insufficient stock.', 16, 1);
        RETURN;
    END

    -- If sufficient stock, insert the order detail and decrement stock
    INSERT INTO [Order Details] (OrderDetailID, OrderID, ProductID, Quantity)
    SELECT OrderDetailID, OrderID, ProductID, Quantity
    FROM inserted;

    UPDATE p
    SET UnitsInStock = UnitsInStock - i.Quantity
    FROM Products p
    JOIN inserted i ON p.ProductID = i.ProductID;
END
GO

--Testing trigger
-- Successful insert
INSERT INTO [Order Details] (OrderDetailID, OrderID, ProductID, Quantity) VALUES (101, 1, 1, 5);
