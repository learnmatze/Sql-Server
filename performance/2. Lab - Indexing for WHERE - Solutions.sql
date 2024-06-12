/*
Fundamentals of Index Tuning: WHERE Lab

v1.1 - 2019-06-03

https://www.BrentOzar.com/go/indexfund


This demo requires:
* Any supported version of SQL Server
* Any Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO

use StackOverflow2010
go

CREATE OR ALTER PROCEDURE dbo.DropIndexes 
  @SchemaName NVARCHAR(255) = 'dbo', 
  @TableName NVARCHAR(255) = NULL, 
  @WhatToDrop VARCHAR(10) = 'Everything',
  @ExceptIndexNames NVARCHAR(MAX) = NULL
  AS
BEGIN
SET NOCOUNT ON;
SET STATISTICS XML OFF;
 
CREATE TABLE #commands (ID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, Command NVARCHAR(2000));

CREATE TABLE #ExceptIndexNames (IndexName NVARCHAR(1000));
INSERT INTO #ExceptIndexNames(IndexName)
  SELECT UPPER(LTRIM(RTRIM(value)))
    FROM string_split(@ExceptIndexNames,',');
 
DECLARE @CurrentCommand NVARCHAR(2000);
 
IF ( UPPER(@WhatToDrop) LIKE 'C%' 
     OR UPPER(@WhatToDrop) LIKE 'E%' )
BEGIN
INSERT INTO #commands (Command)
SELECT   N'ALTER TABLE ' 
       + QUOTENAME(SCHEMA_NAME(o.schema_id))
       + N'.'
       + QUOTENAME(OBJECT_NAME(o.parent_object_id))
       + N' DROP CONSTRAINT '
       + QUOTENAME(o.name)
       + N';'
FROM sys.objects AS o
WHERE o.type IN ('C', 'F', 'UQ')
AND SCHEMA_NAME(o.schema_id) = COALESCE(@SchemaName, SCHEMA_NAME(o.schema_id)) COLLATE DATABASE_DEFAULT
AND OBJECT_NAME(o.parent_object_id) = COALESCE(@TableName,  OBJECT_NAME(o.parent_object_id)) COLLATE DATABASE_DEFAULT
AND UPPER(o.name) NOT IN (SELECT IndexName COLLATE DATABASE_DEFAULT FROM #ExceptIndexNames);
END;
 
IF ( UPPER(@WhatToDrop) LIKE 'I%' 
     OR UPPER(@WhatToDrop) LIKE 'E%' )
BEGIN
INSERT INTO #commands (Command)
SELECT 'DROP INDEX ' 
       + QUOTENAME(i.name) 
       + ' ON ' 
       + QUOTENAME(SCHEMA_NAME(t.schema_id)) 
       + '.' 
       + t.name 
       + ';'
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
WHERE i.type NOT IN (0, 1, 5)
AND SCHEMA_NAME(t.schema_id) = COALESCE(@SchemaName, SCHEMA_NAME(t.schema_id)) COLLATE DATABASE_DEFAULT
AND t.name = COALESCE(@TableName, t.name) COLLATE DATABASE_DEFAULT
AND UPPER(i.name) NOT IN (SELECT IndexName COLLATE DATABASE_DEFAULT FROM #ExceptIndexNames);

INSERT INTO #commands (Command)
SELECT 'DROP STATISTICS ' 
       + QUOTENAME(SCHEMA_NAME(t.schema_id)) 
       + '.'  
       + QUOTENAME(OBJECT_NAME(s.object_id)) 
       + '.' 
       + QUOTENAME(s.name)
       + ';'
FROM sys.stats AS s
INNER JOIN sys.tables AS t ON s.object_id = t.object_id
WHERE NOT EXISTS (SELECT * FROM sys.indexes AS i WHERE i.name = s.name) 
AND SCHEMA_NAME(t.schema_id) = COALESCE(@SchemaName, SCHEMA_NAME(t.schema_id))
AND t.name = COALESCE(@TableName, t.name)
AND OBJECT_NAME(s.object_id) NOT LIKE 'sys%';
END; 
 
DECLARE result_cursor CURSOR FOR
SELECT Command FROM #commands;
 
OPEN result_cursor;
FETCH NEXT FROM result_cursor INTO @CurrentCommand;
WHILE @@FETCH_STATUS = 0
BEGIN 
   
    PRINT @CurrentCommand;
	EXEC(@CurrentCommand);
 
FETCH NEXT FROM result_cursor INTO @CurrentCommand;
END;
--end loop
 
--clean up
CLOSE result_cursor;
DEALLOCATE result_cursor;
END;
GO

exec DropIndexes;

/* This stored procedure drops all nonclustered indexes: */
CREATE PROCEDURE DropNonClusteredIndexes
    @SchemaName NVARCHAR(128) = 'dbo'  -- Default to 'dbo' schema if not provided
AS
BEGIN
    SET NOCOUNT ON;
    -- Table to store dynamically generated SQL statements
    DECLARE @sql NVARCHAR(MAX);
    -- Cursor to iterate through each nonclustered index
    DECLARE index_cursor CURSOR FOR
    SELECT 
        QUOTENAME(s.name) AS SchemaName,
        QUOTENAME(o.name) AS TableName,
        QUOTENAME(i.name) AS IndexName
    FROM 
        sys.indexes i
    JOIN 
        sys.objects o ON i.object_id = o.object_id
    JOIN 
        sys.schemas s ON o.schema_id = s.schema_id
    WHERE 
        s.name = @SchemaName
        AND o.type = 'U'  -- Only user tables
        AND i.type = 2;  -- Only nonclustered indexes
    -- Open the cursor
    OPEN index_cursor;
    -- Declare variables to hold schema, table, and index names
    DECLARE @Schema NVARCHAR(128);
    DECLARE @Table NVARCHAR(128);
    DECLARE @Index NVARCHAR(128);
    -- Loop through each index
    FETCH NEXT FROM index_cursor INTO @Schema, @Table, @Index;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Construct the DROP INDEX statement
        SET @sql = 'DROP INDEX ' + @Index + ' ON ' + @Schema + '.' + @Table + ';';
        -- Execute the DROP INDEX statement
        EXEC sp_executesql @sql;
        -- Fetch the next index
        FETCH NEXT FROM index_cursor INTO @Schema, @Table, @Index;
    END
    -- Close and deallocate the cursor
    CLOSE index_cursor;
    DEALLOCATE index_cursor;
END
GO

exec DropNonClusteredIndexes

/* ****************************************************************************
FIRST LAB CHALLENGE: design the right index for this:
*/
SELECT DisplayName, Id
  FROM dbo.Users
  WHERE WebsiteUrl = 'http://127.0.0.1'
    AND Location = 'United States';
GO

select count(*) from dbo.Users where WebsiteUrl = 'http://127.0.0.1'
select count(*) from dbo.Users where Location = 'United States';

/* 
Which field should go first in the WHERE clause?
Which filter is more selective?
*/
SELECT COUNT(*) AS NumberOfRowsInTheTable FROM dbo.Users;

SELECT COUNT(*) /* DisplayName, Id */
  FROM dbo.Users
  WHERE WebsiteUrl = 'http://127.0.0.1'
    /* AND Location = 'United States'; */

SELECT COUNT(*) /* DisplayName, Id */
  FROM dbo.Users
  WHERE /* WebsiteUrl = 'http://127.0.0.1'
    AND */ Location = 'United States';

SELECT
    TotalRows,
	EqLocationMatchingRows,		
	EqWebsiteUrlMatchingRows,
    CAST(EqLocationMatchingRows AS FLOAT) / TotalRows AS Selectivity_EqLocation,
    CAST(EqWebsiteUrlMatchingRows as FLOAT) / TotalRows AS Selectivity_EqWebsiteUrl  
FROM
    (SELECT
        (SELECT COUNT(*) FROM dbo.Users WHERE Location = 'United States') AS EqLocationMatchingRows,
        (SELECT COUNT(*) FROM dbo.Users WHERE WebsiteUrl = 'http://127.0.0.1') AS EqWebsiteUrlMatchingRows,        
        (SELECT COUNT(*) FROM dbo.Users) AS TotalRows
    ) AS Counts;

/* 
Looks like our WebsiteUrl is more selective for these parameters.
(If we change the parameter values, that might not be the case anymore.)

This one seems best:
*/

CREATE INDEX IX_WebsiteUrl_Location_Includes 
  ON dbo.Users(WebsiteUrl, Location) 
  INCLUDE (DisplayName); /* The fields from our SELECT */

/* For testing purposes, we'll also create the opposite index: */
CREATE INDEX IX_Location_WebsiteUrl_Includes 
  ON dbo.Users(Location, WebsiteUrl) 
  INCLUDE (DisplayName); /* The fields from our SELECT */
GO



/* Now take your original query, and run it with hints to test which index
gives you the lowest logical reads: */

sp_help Users

SET STATISTICS IO ON;
GO
SELECT DisplayName, Id
  FROM dbo.Users WITH (INDEX = 1) /* The original clustered index */
  WHERE WebsiteUrl = 'http://127.0.0.1'
    AND Location = 'United States';

SELECT DisplayName, Id
  FROM dbo.Users WITH (INDEX = IX_WebsiteUrl_Location_Includes)
  WHERE WebsiteUrl = 'http://127.0.0.1'
    AND Location = 'United States';

SELECT DisplayName, Id
  FROM dbo.Users WITH (INDEX = IX_Location_WebsiteUrl_Includes)
  WHERE WebsiteUrl = 'http://127.0.0.1'
    AND Location = 'United States';
GO


/* It's a dead heat! They're both good for these parameters.
Either one would be totally fine.

Alright, you're up next. */

/* ****************************************************************************
NEXT EXERCISE: design the right index to find the nicest people:
*/
SELECT DisplayName, Location, UpVotes, Id
  FROM dbo.Users
  WHERE DownVotes = 0
    AND UpVotes > 100;
GO

select count(*) from users where DownVotes = 0;
select count(*) from users where UpVotes > 100;

create index UpVotes_DownVotes on dbo.Users(UpVotes, DownVotes)
include (displayname, Location)

create index DownVotes_UpVotes on dbo.Users(DownVotes, UpVotes)
include (displayname, Location)

SELECT DisplayName, Location, UpVotes, Id
  FROM dbo.Users with (index=1)
  WHERE DownVotes = 0
    AND UpVotes > 100;
GO

SELECT DisplayName, Location, UpVotes, Id
  FROM dbo.Users with (index=UpVotes_DownVotes)
  WHERE DownVotes = 0
    AND UpVotes > 100;
GO

SELECT DisplayName, Location, UpVotes, Id
  FROM dbo.Users with (index=DownVotes_UpVotes)
  WHERE DownVotes = 0
    AND UpVotes > 100;
GO

select upvotes, downvotes, DisplayName, location,id
from dbo.Users
where UpVotes > 100
order by upvotes, downvotes

select downvotes, upvotes, DisplayName, location,id
from dbo.Users
where DownVotes = 0 and upvotes > 100
order by downvotes, upvotes

/* ****************************************************************************
NEXT EXERCISE: find German people with a high reputation:
*/
exec DropIndexes;
go

SELECT DisplayName, Location, Reputation, Id
  FROM dbo.Users
  WHERE Location LIKE '%Germany%'
    AND Reputation > 100000;
GO

select count(*) Specifity_Location from users where Location LIKE '%Germany%';
select count(*) Specifity_Reputation from users where Reputation > 100000;

create index reputation on dbo.users(reputation)
create index reputation_location on dbo.users(reputation, location)
	include(DisplayName) --with (DROP_EXISTING=ON);

create index reputation on dbo.users(reputation)
	include(location, DisplayName)

SELECT DisplayName, Location, Reputation, Id
  FROM dbo.Users with (index=reputation_location)
  WHERE Location LIKE '%Germany%'
    AND Reputation > 100000;
GO
SELECT DisplayName, Location, Reputation, Id
  FROM dbo.Users with (index=reputation)
  WHERE Location LIKE '%Germany%'
    AND Reputation > 100000;

/* ****************************************************************************
LET'S MIX THINGS UP: You've created a few indexes so far. Pick one of them,
and write 3 queries:

* One that will scan the index (and only that index, not touching any others)*/
exec DropIndexes;
go

create index reputation_location on dbo.users(reputation, location)
	include(DisplayName) --with (DROP_EXISTING=ON);

select count(displayname) from dbo.users
sp_blitzindex @Tablename = 'Users'

select top 100 reputation, location, displayname, id
from dbo.users
order by reputation desc, location desc

/*
* Write a query that will do an index seek (but again, not touching any others)*/

select reputation, location, displayname, id
from users
--where reputation = 8765309
--where reputation > 100 and reputation < 102
where location = 'Las Vegas, NV'

/* Write a query that will use that index, but then get a residual predicate
  (Reminder: that's a query that uses the index to do a seek, but then has to
  do an additional filter, like maybe going over to the clustered index to do a
  key lookup, and do additional filtering there)
*/
select reputation, location, displayname, id
from users
--where reputation = 12345 and DisplayName = 'Brent Ozar'
where reputation > 0 and DisplayName = 'Brent Ozar'


/* ****************************************************************************
NEXT UP: find people who match an unusual filter:
*/
SELECT DisplayName, Location, Reputation, Id
  FROM dbo.Users
  WHERE Location = 'Moscow, Russia'
     OR DisplayName LIKE 'Dmitry%';
GO

select count(*) Specifity_Location from users where Location = 'Moscow, Russia'
select count(*) Specifity_DisplayName from users where DisplayName LIKE 'Dmitry%';

exec DropIndexes;
go

create index location on dbo.users(Location) 
create index displayname on dbo.users(Displayname)

create index location on dbo.users(Location) include (displayname, reputation)
create index displayname on dbo.users(Displayname) include (location, reputation)


/* ****************************************************************************
NEXT QUESTION: design the right index to find all of the people who created an
account, but then never accessed the system again:
*/
exec DropIndexes;
go

SELECT CreationDate, LastAccessDate, DisplayName, Id
  FROM dbo.Users
  WHERE CreationDate = LastAccessDate;
GO

create index CreationDate_LastAccessDate on dbo.users(CreationDate, LastAccessDate)
	include (displayname);
create index LastAccessDate_CreationDate on dbo.users(LastAccessDate, CreationDate)
	include (displayname);

SELECT CreationDate, LastAccessDate, DisplayName, Id
  FROM dbo.Users with (index=CreationDate_LastAccessDate)
  WHERE CreationDate = LastAccessDate;
GO

SELECT CreationDate, LastAccessDate, DisplayName, Id
  FROM dbo.Users with (index=LastAccessDate_CreationDate)
  WHERE CreationDate = LastAccessDate;
GO

create index DisplayName on dbo.users(Displayname)
	include (CreationDate, LastAccessDate)

SELECT CreationDate, LastAccessDate, DisplayName, Id
  FROM dbo.Users with (index=DisplayName)
  WHERE CreationDate = LastAccessDate;
GO

