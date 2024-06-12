/*
Fundamentals of Index Tuning: ORDER BY Clause

v1.2 - 2019-09-04

https://www.BrentOzar.com/go/indexfund


This demo requires:
* Any supported version of SQL Server
* Any Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO



/* This stored procedure drops all nonclustered indexes: */
DropIndexes;
GO
/* It leaves clustered indexes in place though. */

SET STATISTICS IO ON;
GO

/* Create the perfect index for this - note the equality on Location: */
SELECT Id, DisplayName, Location
    FROM dbo.Users
    WHERE DisplayName = 'alex'
        AND Location = 'Seattle, WA'
  ORDER BY Reputation;
GO


/* Create our earlier indexes, but add Reputation to them: */
CREATE INDEX IX_DisplayName_Location_Reputation
  ON dbo.Users(DisplayName, Location, Reputation);

CREATE INDEX IX_Location_DisplayName_Reputation
  ON dbo.Users(Location, DisplayName, Reputation);

/* Plus a third idea: */
CREATE INDEX IX_Reputation_DisplayName_Location
  ON dbo.Users(Reputation, DisplayName, Location);
GO

/* Measure them: */
SELECT Id, DisplayName, Location
    FROM dbo.Users WITH (INDEX = 1)
    WHERE DisplayName = 'alex'
        AND Location = 'Seattle, WA'
  ORDER BY Reputation;

SELECT Id, DisplayName, Location
    FROM dbo.Users WITH (INDEX = IX_DisplayName_Location_Reputation)
    WHERE DisplayName = 'alex'
        AND Location = 'Seattle, WA'
  ORDER BY Reputation;

SELECT Id, DisplayName, Location
    FROM dbo.Users WITH (INDEX = IX_Location_DisplayName_Reputation)
    WHERE DisplayName = 'alex'
        AND Location = 'Seattle, WA'
  ORDER BY Reputation;

SELECT Id, DisplayName, Location
    FROM dbo.Users WITH (INDEX = IX_Reputation_DisplayName_Location)
    WHERE DisplayName = 'alex'
        AND Location = 'Seattle, WA'
  ORDER BY Reputation;
GO

/* Count the number of pages in each index: */
SELECT COUNT(*)
    FROM dbo.Users WITH (INDEX = 1);

SELECT COUNT(*)
    FROM dbo.Users WITH (INDEX = IX_DisplayName_Location_Reputation);

SELECT COUNT(*)
    FROM dbo.Users WITH (INDEX = IX_Location_DisplayName_Reputation);

SELECT COUNT(*)
    FROM dbo.Users WITH (INDEX = IX_Reputation_DisplayName_Location);
GO

/* Which one does SQL Server pick? */
SELECT Id, DisplayName, Location
    FROM dbo.Users
    WHERE DisplayName = 'alex'
        AND Location = 'Seattle, WA'
  ORDER BY Reputation;
GO




/* Create the perfect index for this - note the INequality on Location: */
SELECT Id, DisplayName, Location
    FROM dbo.Users
    WHERE DisplayName = 'alex'
        AND Location <> 'Seattle, WA'
  ORDER BY Reputation;
GO


/* Turn on actual plans: */
SELECT Id, DisplayName, Location
    FROM dbo.Users
    WHERE DisplayName = 'alex'
        AND Location <> 'Seattle, WA'
  ORDER BY Reputation;
GO

/* Visualize the index: */
SELECT DisplayName, Location, Reputation, Id
FROM dbo.Users
ORDER BY DisplayName, Location, Reputation;


CREATE INDEX IX_DisplayName_Location_Includes 
  ON dbo.Users(DisplayName, Location) INCLUDE (Reputation);
GO

SET STATISTICS IO, TIME ON;

SELECT Id, DisplayName, Location
    FROM dbo.Users WITH (INDEX = IX_DisplayName_Location_Reputation)
    WHERE DisplayName = 'alex'
        AND Location <> 'Seattle, WA'
  ORDER BY Reputation;

SELECT Id, DisplayName, Location
    FROM dbo.Users WITH (INDEX = IX_DisplayName_Location_Includes)
    WHERE DisplayName = 'alex'
        AND Location <> 'Seattle, WA'
  ORDER BY Reputation;
GO



/* Promote Reputation one level: */
CREATE INDEX IX_DisplayName_Reputation_Location 
  ON dbo.Users(DisplayName, Reputation, Location);
GO

/* And the sort is gone: */
SELECT Id, DisplayName, Location
    FROM dbo.Users WITH (INDEX = IX_DisplayName_Reputation_Location)
    WHERE DisplayName = 'alex'
        AND Location <> 'Seattle, WA'
  ORDER BY Reputation;
GO

/* Which one does SQL Server pick? */
SELECT Id, DisplayName, Location
    FROM dbo.Users
    WHERE DisplayName = 'alex'
        AND Location <> 'Seattle, WA'
  ORDER BY Reputation;
GO



EXEC DropIndexes;
GO

/* The original query: */
SELECT TOP 100 Id, Reputation, CreationDate
    FROM dbo.Users
    WHERE Reputation > 1
    ORDER BY CreationDate ASC;
GO


CREATE INDEX IX_Reputation_CreationDate
  ON dbo.Users(Reputation, CreationDate);

CREATE INDEX IX_CreationDate_Reputation
  ON dbo.Users(CreationDate, Reputation);
GO


/* Test 'em */
SELECT TOP 100 Id, Reputation, CreationDate
    FROM dbo.Users WITH (INDEX = 1)
    WHERE Reputation > 1
    ORDER BY CreationDate ASC;

SELECT TOP 100 Id, Reputation, CreationDate
    FROM dbo.Users WITH (INDEX = IX_Reputation_CreationDate)
    WHERE Reputation > 1
    ORDER BY CreationDate ASC;

SELECT TOP 100 Id, Reputation, CreationDate
    FROM dbo.Users WITH (INDEX = IX_CreationDate_Reputation)
    WHERE Reputation > 1
    ORDER BY CreationDate ASC;
GO

/* Check object sizes: */
SELECT COUNT(*)
    FROM dbo.Users WITH (INDEX = IX_Reputation_CreationDate);

SELECT COUNT(*)
    FROM dbo.Users WITH (INDEX = IX_CreationDate_Reputation);
GO



/* Let's say we call the below one the winner: */
DropIndexes;
GO
CREATE INDEX IX_CreationDate_Reputation
  ON dbo.Users(CreationDate, Reputation);
GO

/* The original query: */
SELECT TOP 100 Id, Reputation, CreationDate
    FROM dbo.Users
    WHERE Reputation > 1
    ORDER BY CreationDate ASC;

/* The new one looking for Jon Skeet: */
SELECT TOP 100 Id, Reputation, CreationDate
    FROM dbo.Users
    WHERE Reputation > 1000000
    ORDER BY CreationDate ASC;
GO





/*
License: Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
More info: https://creativecommons.org/licenses/by-sa/3.0/

You are free to:
* Share - copy and redistribute the material in any medium or format
* Adapt - remix, transform, and build upon the material for any purpose, even 
  commercially

Under the following terms:
* Attribution - You must give appropriate credit, provide a link to the license,
  and indicate if changes were made.
* ShareAlike - If you remix, transform, or build upon the material, you must
  distribute your contributions under the same license as the original.
*/