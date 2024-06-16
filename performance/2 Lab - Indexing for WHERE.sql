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

use StackOverflow2013

/* This stored procedure drops all nonclustered indexes: */
DropIndexes;
GO
/* It leaves clustered indexes in place though. */





/* ****************************************************************************
FIRST LAB CHALLENGE: design the right index for this:
*/

set statistics io on;

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






/* ****************************************************************************
NEXT EXERCISE: find German people with a high reputation:
*/
SELECT DisplayName, Location, Reputation, Id
  FROM dbo.Users
  WHERE Location LIKE '%Germany%'
    AND Reputation > 100000;
GO



/* ****************************************************************************
LET'S MIX THINGS UP: You've created a few indexes so far. Pick one of them,
and write 3 queries:

* One that will scan the index (and only that index, not touching any others)
* Write a query that will do an index seek (but again, not touching any others)
* Write a query that will use that index, but then get a residual predicate
  (Reminder: that's a query that uses the index to do a seek, but then has to
  do an additional filter, like maybe going over to the clustered index to do a
  key lookup, and do additional filtering there)
*/




/* ****************************************************************************
NEXT UP: find people who match an unusual filter:
*/
SELECT DisplayName, Location, Reputation, Id
  FROM dbo.Users
  WHERE Location = 'Moscow, Russia'
     OR DisplayName LIKE 'Dmitry%';
GO






/* ****************************************************************************
NEXT QUESTION: design the right index to find all of the people who created an
account, but then never accessed the system again:
*/
SELECT CreationDate, LastAccessDate, DisplayName, Id
  FROM dbo.Users
  WHERE CreationDate = LastAccessDate;
GO





/* ****************************************************************************
TRICKY BONUS QUESTION: design the right index for this.
*/

SELECT CreationDate, DisplayName, Location
  FROM dbo.Users
  WHERE CreationDate >= '2009-01-01'
    AND CreationDate < '2009-01-02'
    AND Reputation = 1;
GO
/* 
It has two fields in the WHERE clause. Figure out which one should go first
using the same methods we've been using so far, but after you have both indexes
in place, test them.

Which part of the where clause is more selective?
Which index has less logical reads?

Here's the tricky part: why?
*/




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