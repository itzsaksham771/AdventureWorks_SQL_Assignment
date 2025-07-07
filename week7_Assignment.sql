-- Main Dimension Table
CREATE TABLE DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    Name NVARCHAR(100),
    Address NVARCHAR(200),
    Email NVARCHAR(100),
    StartDate DATETIME,          -- Used for SCD Type 2/6
    EndDate DATETIME,            -- Used for SCD Type 2/6
    IsCurrent BIT,               -- Used for SCD Type 2/6
    PreviousAddress NVARCHAR(200)  -- Used for SCD Type 3/6
);
GO

-- History Table for SCD Type 4
CREATE TABLE DimCustomer_History (
    HistoryKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    Name NVARCHAR(100),
    Address NVARCHAR(200),
    Email NVARCHAR(100),
    ChangeDate DATETIME DEFAULT GETDATE()
);
GO



CREATE PROCEDURE usp_SCD_Type0_Insert
    @CustomerID INT,
    @Name NVARCHAR(100),
    @Address NVARCHAR(200),
    @Email NVARCHAR(100)
AS
BEGIN
    -- Insert only if the CustomerID does not exist
    IF NOT EXISTS (SELECT 1 FROM DimCustomer WHERE CustomerID = @CustomerID)
    BEGIN
        INSERT INTO DimCustomer (CustomerID, Name, Address, Email)
        VALUES (@CustomerID, @Name, @Address, @Email)
    END
END;
GO



CREATE PROCEDURE usp_SCD_Type1_Upsert
    @CustomerID INT,
    @Name NVARCHAR(100),
    @Address NVARCHAR(200),
    @Email NVARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM DimCustomer WHERE CustomerID = @CustomerID)
    BEGIN
        -- Overwrite existing data
        UPDATE DimCustomer
        SET Name = @Name,
            Address = @Address,
            Email = @Email
        WHERE CustomerID = @CustomerID
    END
    ELSE
    BEGIN
        INSERT INTO DimCustomer (CustomerID, Name, Address, Email)
        VALUES (@CustomerID, @Name, @Address, @Email)
    END
END;
GO










CREATE PROCEDURE usp_SCD_Type2_Upsert
    @CustomerID INT,
    @Name NVARCHAR(100),
    @Address NVARCHAR(200),
    @Email NVARCHAR(100)
AS
BEGIN
    DECLARE @ExistingID INT

    -- Get current active record
    SELECT @ExistingID = CustomerKey
    FROM DimCustomer
    WHERE CustomerID = @CustomerID AND IsCurrent = 1

    IF @ExistingID IS NULL
    BEGIN
        -- Insert if not present
        INSERT INTO DimCustomer (CustomerID, Name, Address, Email, StartDate, EndDate, IsCurrent)
        VALUES (@CustomerID, @Name, @Address, @Email, GETDATE(), NULL, 1)
    END
    ELSE
    BEGIN
        -- Check if data has changed
        IF EXISTS (
            SELECT 1 FROM DimCustomer
            WHERE CustomerID = @CustomerID AND IsCurrent = 1 AND 
                (Name <> @Name OR Address <> @Address OR Email <> @Email)
        )
        BEGIN
            -- Expire old record
            UPDATE DimCustomer
            SET EndDate = GETDATE(), IsCurrent = 0
            WHERE CustomerKey = @ExistingID

            -- Insert new record
            INSERT INTO DimCustomer (CustomerID, Name, Address, Email, StartDate, EndDate, IsCurrent)
            VALUES (@CustomerID, @Name, @Address, @Email, GETDATE(), NULL, 1)
        END
    END
END;
GO







CREATE PROCEDURE usp_SCD_Type3_Upsert
    @CustomerID INT,
    @Name NVARCHAR(100),
    @Address NVARCHAR(200),
    @Email NVARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM DimCustomer WHERE CustomerID = @CustomerID)
    BEGIN
        -- Shift current address to PreviousAddress
        UPDATE DimCustomer
        SET PreviousAddress = Address,
            Address = @Address
        WHERE CustomerID = @CustomerID
    END
    ELSE
    BEGIN
        -- Insert new record
        INSERT INTO DimCustomer (CustomerID, Name, Address, Email, PreviousAddress)
        VALUES (@CustomerID, @Name, @Address, @Email, NULL)
    END
END;
GO












CREATE PROCEDURE usp_SCD_Type4_Upsert
    @CustomerID INT,
    @Name NVARCHAR(100),
    @Address NVARCHAR(200),
    @Email NVARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM DimCustomer WHERE CustomerID = @CustomerID)
    BEGIN
        -- Archive old data
        INSERT INTO DimCustomer_History (CustomerID, Name, Address, Email)
        SELECT CustomerID, Name, Address, Email
        FROM DimCustomer
        WHERE CustomerID = @CustomerID

        -- Update current table
        UPDATE DimCustomer
        SET Name = @Name,
            Address = @Address,
            Email = @Email
        WHERE CustomerID = @CustomerID
    END
    ELSE
    BEGIN
        INSERT INTO DimCustomer (CustomerID, Name, Address, Email)
        VALUES (@CustomerID, @Name, @Address, @Email)
    END
END;
GO






CREATE PROCEDURE usp_SCD_Type6_Upsert
    @CustomerID INT,
    @Name NVARCHAR(100),
    @Address NVARCHAR(200),
    @Email NVARCHAR(100)
AS
BEGIN
    DECLARE @ExistingID INT

    -- Get current active record
    SELECT @ExistingID = CustomerKey
    FROM DimCustomer
    WHERE CustomerID = @CustomerID AND IsCurrent = 1

    IF @ExistingID IS NULL
    BEGIN
        -- First insert
        INSERT INTO DimCustomer (CustomerID, Name, Address, Email, StartDate, EndDate, IsCurrent, PreviousAddress)
        VALUES (@CustomerID, @Name, @Address, @Email, GETDATE(), NULL, 1, NULL)
    END
    ELSE
    BEGIN
        -- Check for changes
        IF EXISTS (
            SELECT 1 FROM DimCustomer
            WHERE CustomerID = @CustomerID AND IsCurrent = 1 AND 
                (Name <> @Name OR Address <> @Address OR Email <> @Email)
        )
        BEGIN
            -- Expire current record
            UPDATE DimCustomer
            SET EndDate = GETDATE(), IsCurrent = 0
            WHERE CustomerKey = @ExistingID

            -- Insert new record with historical address
            INSERT INTO DimCustomer (
                CustomerID, Name, Address, Email, StartDate, EndDate, IsCurrent, PreviousAddress
            )
            SELECT
                @CustomerID, @Name, @Address, @Email, GETDATE(), NULL, 1, Address
            FROM DimCustomer
            WHERE CustomerKey = @ExistingID
        END
    END
END;
GO
