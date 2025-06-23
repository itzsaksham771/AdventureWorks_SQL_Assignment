USE AdventureWorks2022;
GO

-- Drop and create SubjectAllotments table
IF OBJECT_ID('dbo.SubjectAllotments', 'U') IS NOT NULL
    DROP TABLE dbo.SubjectAllotments;
GO

CREATE TABLE SubjectAllotments (
    StudentId VARCHAR(20),
    SubjectId VARCHAR(20),
    Is_Valid BIT
);
GO

-- Drop and create SubjectRequest table
IF OBJECT_ID('dbo.SubjectRequest', 'U') IS NOT NULL
    DROP TABLE dbo.SubjectRequest;
GO

CREATE TABLE SubjectRequest (
    StudentId VARCHAR(20),
    SubjectId VARCHAR(20)
);
GO

-- Insert initial data into SubjectAllotments
INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_Valid)
VALUES
('159103036', 'PO1491', 1),
('159103036', 'PO1492', 0),
('159103036', 'PO1493', 0),
('159103036', 'PO1494', 0),
('159103036', 'PO1495', 0);
GO

-- Insert request data into SubjectRequest
INSERT INTO SubjectRequest (StudentId, SubjectId)
VALUES
('159103036', 'PO1496');
GO

-- Drop procedure if exists
IF OBJECT_ID('dbo.ProcessSubjectRequests', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ProcessSubjectRequests;
GO

--Now CREATE PROCEDURE starts in a fresh batch
CREATE PROCEDURE ProcessSubjectRequests
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StudentId VARCHAR(20), @RequestedSubjectId VARCHAR(20), @CurrentSubjectId VARCHAR(20);

    DECLARE request_cursor CURSOR FOR
    SELECT StudentId, SubjectId FROM SubjectRequest;

    OPEN request_cursor;
    FETCH NEXT FROM request_cursor INTO @StudentId, @RequestedSubjectId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Get current valid subject for the student
        SELECT @CurrentSubjectId = SubjectId
        FROM SubjectAllotments
        WHERE StudentId = @StudentId AND Is_Valid = 1;

        -- If student already has subject allotments
        IF EXISTS (
            SELECT 1 FROM SubjectAllotments WHERE StudentId = @StudentId
        )
        BEGIN
            -- If requested subject is different from current active subject
            IF (@CurrentSubjectId IS NOT NULL AND @CurrentSubjectId <> @RequestedSubjectId)
            BEGIN
                -- Mark current active subject as invalid
                UPDATE SubjectAllotments
                SET Is_Valid = 0
                WHERE StudentId = @StudentId AND Is_Valid = 1;

                -- Insert new subject as active
                INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_Valid)
                VALUES (@StudentId, @RequestedSubjectId, 1);
            END
        END
        ELSE
        BEGIN
            -- Student not present in SubjectAllotments, insert as valid directly
            INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_Valid)
            VALUES (@StudentId, @RequestedSubjectId, 1);
        END

        FETCH NEXT FROM request_cursor INTO @StudentId, @RequestedSubjectId;
    END

    CLOSE request_cursor;
    DEALLOCATE request_cursor;
END;
GO

-- Execute the procedure
EXEC ProcessSubjectRequests;
GO

-- View result
SELECT * FROM SubjectAllotments
ORDER BY StudentId, Is_Valid DESC;
GO
