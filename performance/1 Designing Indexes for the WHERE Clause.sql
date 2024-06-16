/*
Fundamentals of Index Tuning: WHERE Clause

v1.3 - 2023-11-01

https://www.BrentOzar.com/go/indexfund


This demo requires:
* Any supported version of SQL Server
* Any Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO


/* I'm using the 50GB medium Stack database: */
USE StackOverflow2013;
GO
/* And this stored procedure drops all nonclustered indexes: */
DropIndexes;
GO
/* It leaves clustered indexes in place though. */
CREATE INDEX Age ON dbo.Users(Age) /* To avoid trivial optimization */

SET STATISTICS IO ON;

/* Design an index for this: */
SELECT Id, DisplayName, Location
  FROM dbo.Users
  WHERE DisplayName = 'alex';

CREATE INDEX IX_DisplayName_Includes
  ON dbo.Users(DisplayName)
  INCLUDE (Location);

SELECT Id, DisplayName, Location
  FROM dbo.Users
  WHERE DisplayName = 'alex';


/* Design an index for this: */
SELECT Id, DisplayName, Location
  FROM dbo.Users
  WHERE DisplayName = 'alex'
    AND Location = 'Seattle, WA';
DROP INDEX IX_DisplayName_Includes ON dbo.Users;
GO
/* But we already have this.... */
CREATE INDEX IX_DisplayName_Includes
  ON dbo.Users(DisplayName)
  INCLUDE (Location);

/* Visualize the index: */
SELECT DisplayName, Location
  FROM dbo.Users
  ORDER BY DisplayName;

/* Visualize the index contents: */
SELECT DisplayName, Location
  FROM dbo.Users
  WHERE DisplayName = 'alex'
  ORDER BY DisplayName;

/* Create a couple of index options: */
CREATE INDEX IX_DisplayName_Location
  ON dbo.Users(DisplayName, Location);

CREATE INDEX IX_Location_DisplayName
  ON dbo.Users(Location, DisplayName);
GO

/* Test 'em with index hints: */
SET STATISTICS IO ON;
GO
SELECT Id, DisplayName, Location
  FROM dbo.Users WITH (INDEX = 1) /* Clustered index scan */
  WHERE DisplayName = N'alex'
    AND Location = N'Seattle, WA';

SELECT Id, DisplayName, Location
  FROM dbo.Users WITH (INDEX = IX_DisplayName_Includes)
  WHERE DisplayName = N'alex'
    AND Location = N'Seattle, WA';

SELECT Id, DisplayName, Location
  FROM dbo.Users WITH (INDEX = IX_DisplayName_Location)
  WHERE DisplayName = N'alex'
    AND Location = N'Seattle, WA';

SELECT Id, DisplayName, Location
  FROM dbo.Users WITH (INDEX = IX_Location_DisplayName)
  WHERE DisplayName = N'alex'
    AND Location = N'Seattle, WA';
GO

/* Which one does SQL Server pick? */
SELECT Id, DisplayName, Location
  FROM dbo.Users
  WHERE DisplayName = N'alex'
    AND Location = N'Seattle, WA';
GO

SELECT
    TotalRows,
	EqDisplayNameMatchingRows,
	EqLocationMatchingRows,
	UneqLocationMatchingRows,
    CAST(EqDisplayNameMatchingRows AS FLOAT) / TotalRows AS Selectivity_EqDisplayName,
    CAST(EqLocationMatchingRows as FLOAT) / TotalRows AS Selectivity_EqLocation,
    CAST(UneqLocationMatchingRows AS FLOAT) / TotalRows AS Selectivity_UneqLocation
FROM
    (SELECT
        (SELECT COUNT(*) FROM dbo.Users WHERE DisplayName = 'alex') AS EqDisplayNameMatchingRows,
        (SELECT COUNT(*) FROM dbo.Users WHERE Location = 'Seattle, WA') AS EqLocationMatchingRows,
        (SELECT COUNT(*) FROM dbo.Users WHERE Location <> 'Seattle, WA') AS UneqLocationMatchingRows,
        (SELECT COUNT(*) FROM dbo.Users) AS TotalRows
    ) AS Counts;


SET STATISTICS IO ON;
GO
SELECT Id, DisplayName, Location
  FROM dbo.Users WITH (INDEX = 1) /* Clustered index scan */
  WHERE DisplayName = N'alex'
    AND Location <> N'Seattle, WA';

SELECT Id, DisplayName, Location
  FROM dbo.Users WITH (INDEX = IX_DisplayName_Includes)
  WHERE DisplayName = N'alex'
    AND Location <> N'Seattle, WA';

SELECT Id, DisplayName, Location
  FROM dbo.Users WITH (INDEX = IX_DisplayName_Location)
  WHERE DisplayName = N'alex'
    AND Location <> N'Seattle, WA';

SELECT Id, DisplayName, Location
  FROM dbo.Users WITH (INDEX = IX_Location_DisplayName)
  WHERE DisplayName = N'alex'
    AND Location <> N'Seattle, WA';
GO

/* Showing the total pages in each index: */
SELECT COUNT(*)
  FROM dbo.Users WITH (INDEX = 1) /* Clustered index scan */

SELECT COUNT(*)
  FROM dbo.Users WITH (INDEX = IX_DisplayName_Includes)

SELECT COUNT(*)
  FROM dbo.Users WITH (INDEX = IX_DisplayName_Location)

SELECT COUNT(*)
  FROM dbo.Users WITH (INDEX = IX_Location_DisplayName)
GO

/* Which one does SQL Server pick? */
SELECT Id, DisplayName, Location
  FROM dbo.Users
  WHERE DisplayName = N'alex'
    AND Location <> N'Seattle, WA';
GO

SELECT
    TotalRows,
	EqDisplayNameMatchingRows,
	EqLocationMatchingRows,
	UneqLocationMatchingRows,
    CAST(EqDisplayNameMatchingRows AS FLOAT) / TotalRows AS Selectivity_EqDisplayName,
    CAST(EqLocationMatchingRows as FLOAT) / TotalRows AS Selectivity_EqLocation,
    CAST(UneqLocationMatchingRows AS FLOAT) / TotalRows AS Selectivity_UneqLocation
FROM
    (SELECT
        (SELECT COUNT(*) FROM dbo.Users WHERE DisplayName = 'alex') AS EqDisplayNameMatchingRows,
        (SELECT COUNT(*) FROM dbo.Users WHERE Location = 'Seattle, WA') AS EqLocationMatchingRows,
        (SELECT COUNT(*) FROM dbo.Users WHERE Location <> 'Seattle, WA') AS UneqLocationMatchingRows,
        (SELECT COUNT(*) FROM dbo.Users) AS TotalRows
    ) AS Counts;






/* Visualizing index contents: */
CREATE INDEX IX_LastAccessDate_Id
  ON dbo.Users(LastAccessDate, Id);
GO
/* Becomes: */
SELECT TOP 1000 LastAccessDate, Id
  FROM dbo.Users
  ORDER BY LastAccessDate, Id;
GO


EXEC DropIndexes;
GO


CREATE INDEX IX_LastAccessDate_Id_DisplayName_Age
  ON dbo.Users(LastAccessDate, Id, DisplayName, Age);
GO
/* Becomes: */
SELECT LastAccessDate, Id, DisplayName, Age
  FROM dbo.Users
  ORDER BY LastAccessDate, Id, DisplayName, Age;
GO


EXEC DropIndexes;
GO



CREATE INDEX IX_LastAccessDate_Id_Includes
  ON dbo.Users(LastAccessDate, Id)
  INCLUDE (DisplayName, Age);
GO
/* Becomes: */
SELECT LastAccessDate, Id, DisplayName, Age
  FROM dbo.Users
  ORDER BY LastAccessDate, Id  /* DisplayName, Age;  These aren't sorted */
GO


EXEC DropIndexes;
GO


/* Now you try: write a SELECT query to visualize each of these: */

CREATE INDEX IX_Reputation_Location_Includes
  ON dbo.Users(Reputation, Location)
  INCLUDE (DisplayName);
GO


CREATE INDEX IX_CreationDate_Views
  ON dbo.Users(CreationDate, Views)
  INCLUDE (DownVotes, UpVotes);
GO


CREATE INDEX IX_Age_Reputation_Location
  ON dbo.Users(Age, Reputation, Location);
GO



EXEC DropIndexes;
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