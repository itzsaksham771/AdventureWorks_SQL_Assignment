-- Drop tables if they exist
DROP TABLE IF EXISTS StudentPreference;
DROP TABLE IF EXISTS SubjectDetails;
DROP TABLE IF EXISTS StudentDetails;
DROP TABLE IF EXISTS Allotments;
DROP TABLE IF EXISTS UnallotedStudents;
GO

-- Create StudentPreference table
CREATE TABLE StudentPreference (
    StudentId INT,
    SubjectId VARCHAR(10),
    Preference INT,
    PRIMARY KEY (StudentId, SubjectId)
);

-- Create SubjectDetails table
CREATE TABLE SubjectDetails (
    SubjectId VARCHAR(10) PRIMARY KEY,
    SubjectName VARCHAR(100),
    MaxSeats INT,
    RemainingSeats INT
);

-- Create StudentDetails table
CREATE TABLE StudentDetails (
    StudentId INT PRIMARY KEY,
    StudentName VARCHAR(100),
    GPA FLOAT,
    Branch VARCHAR(10),
    Section CHAR(1)
);

-- Create Allotments table
CREATE TABLE Allotments (
    SubjectId VARCHAR(10),
    StudentId INT,
    PRIMARY KEY (SubjectId, StudentId)
);

-- Create UnallotedStudents table
CREATE TABLE UnallotedStudents (
    StudentId INT PRIMARY KEY
);
GO

-- Insert sample data
INSERT INTO StudentPreference (StudentId, SubjectId, Preference) VALUES
(159103036, 'PO1491', 1),
(159103036, 'PO1492', 2),
(159103036, 'PO1493', 3),
(159103036, 'PO1494', 4),
(159103036, 'PO1495', 5);

INSERT INTO SubjectDetails (SubjectId, SubjectName, MaxSeats, RemainingSeats) VALUES
('PO1491', 'Basics of Political Science', 60, 2),
('PO1492', 'Basics of Accounting', 120, 119),
('PO1493', 'Basics of Financial Markets', 90, 90),
('PO1494', 'Eco philosophy', 60, 50),
('PO1495', 'Automotive Trends', 60, 60);

INSERT INTO StudentDetails (StudentId, StudentName, GPA, Branch, Section) VALUES
(159103036, 'Mohit Agarwal', 8.9, 'CCE', 'A'),
(159103037, 'Rohit Agarwal', 5.2, 'CCE', 'A'),
(159103038, 'Shohit Garg', 7.1, 'CCE', 'B'),
(159103039, 'Mrinal Malhotra', 7.9, 'CCE', 'A'),
(159103040, 'Mehreet Singh', 5.6, 'CCE', 'A'),
(159103041, 'Arjun Tehlan', 9.2, 'CCE', 'B');
GO

-- Drop procedure if exists
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'AllocateSubjectsToStudents') AND type in (N'P', N'PC'))
DROP PROCEDURE AllocateSubjectsToStudents;
GO

-- Create the stored procedure
CREATE PROCEDURE AllocateSubjectsToStudents
AS
BEGIN
    -- Clear previous allocation results
    DELETE FROM Allotments;
    DELETE FROM UnallotedStudents;
    
    -- Reset remaining seats to max seats
    UPDATE SubjectDetails SET RemainingSeats = MaxSeats;
    
    -- Declare variables for cursor
    DECLARE @StudentId INT, @CurrentPreference INT, @SubjectId VARCHAR(10);
    DECLARE @RemainingSeats INT, @Allocated BIT;
    
    -- Cursor to process students (ordered by GPA descending)
    DECLARE student_cursor CURSOR FOR
    SELECT StudentId FROM StudentDetails ORDER BY GPA DESC;
    
    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Allocated = 0;
        SET @CurrentPreference = 1;
        
        -- Try to allocate based on preferences (1 to 5)
        WHILE @CurrentPreference <= 5 AND @Allocated = 0
        BEGIN
            -- Get the subject for current preference
            SELECT @SubjectId = SubjectId 
            FROM StudentPreference 
            WHERE StudentId = @StudentId AND Preference = @CurrentPreference;
            
            IF @SubjectId IS NOT NULL
            BEGIN
                -- Check remaining seats for this subject
                SELECT @RemainingSeats = RemainingSeats 
                FROM SubjectDetails 
                WHERE SubjectId = @SubjectId;
                
                -- If seats available, allocate
                IF @RemainingSeats > 0
                BEGIN
                    -- Insert into Allotments
                    INSERT INTO Allotments (SubjectId, StudentId) 
                    VALUES (@SubjectId, @StudentId);
                    
                    -- Update remaining seats
                    UPDATE SubjectDetails 
                    SET RemainingSeats = RemainingSeats - 1 
                    WHERE SubjectId = @SubjectId;
                    
                    SET @Allocated = 1;
                END
            END
            
            SET @CurrentPreference = @CurrentPreference + 1;
        END
        
        -- If not allocated after checking all preferences
        IF @Allocated = 0
        BEGIN
            INSERT INTO UnallotedStudents (StudentId) VALUES (@StudentId);
        END
        
        FETCH NEXT FROM student_cursor INTO @StudentId;
    END
    
    CLOSE student_cursor;
    DEALLOCATE student_cursor;
END
GO

-- Execute the procedure
EXEC AllocateSubjectsToStudents;
GO

-- Display results
SELECT 'Allotments' as ResultType, A.SubjectId, A.StudentId, SD.SubjectName, STD.StudentName
FROM Allotments A
JOIN SubjectDetails SD ON A.SubjectId = SD.SubjectId
JOIN StudentDetails STD ON A.StudentId = STD.StudentId

UNION ALL

SELECT 'Unallotted' as ResultType, '' as SubjectId, U.StudentId, '' as SubjectName, STD.StudentName
FROM UnallotedStudents U
JOIN StudentDetails STD ON U.StudentId = STD.StudentId;
