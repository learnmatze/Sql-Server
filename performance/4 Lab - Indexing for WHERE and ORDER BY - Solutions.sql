/*
Fundamentals of Index Tuning: WHERE + ORDER BY Lab

v1.2 - 2020-11-12

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
go


exec DropIndexes;
go
/* It leaves clustered indexes in place though. */





/* ****************************************************************************
FIRST LAB CHALLENGE: design the right index for this:
*/

set statistics io on;

SELECT TOP 100 DisplayName, Location, WebsiteUrl, Reputation, Id
  FROM dbo.Users
  WHERE Location <> ''
    AND WebsiteUrl <> ''
  ORDER BY Reputation DESC;
GO

select count(*) from dbo.Users 
where location <> '';
select count(*) from dbo.Users 
where WebsiteUrl <> '';
select top 100 * from dbo.Users 
order by Reputation desc

create index reputation on dbo.users (Reputation)
include (Location, WebsiteUrl, DisplayName)

select top 100 reputation, WebsiteUrl, location
from users
order by reputation desc

select top 100 reputation, WebsiteUrl, location
from users
order by reputation desc,WebsiteUrl, location

/* ****************************************************************************
NEXT UP: We want to start encouraging people to review other folks' work and
upvote it. To do that, let's find the most recently created users who haven't
cast an UpVote yet. Then, build the right index for it.

You write the query. Go for it!
*/
select top 100 *
from users
where upvotes = 0
order by CreationDate desc;

select count(*) from dbo.Users 
where upvotes = 0
select top 100 * from dbo.Users 
order by CreationDate desc

create index CreationDate On dbo.users(CreationDate)
	include(UpVotes);

create index UpVotes_CreationDate On dbo.users(UpVotes, CreationDate)

/* ****************************************************************************
NEXT CHALLENGE: User Id #22656 is lonely. Let's build a dating service query to
find all of the people who live in his country. He'll probably want to find
friendly people, so let's filter for a few things:
*/

exec DropIndexes;
go

SELECT DisplayName, Location, Reputation, WebsiteUrl, Id
  FROM dbo.Users
  WHERE Age > 21
    AND (Location LIKE '%United Kingdom%' OR Location LIKE '%UK%')
    AND DownVotes < 1000
    AND UpVotes > 1
  ORDER BY Reputation DESC, Location;
GO


select count(*) from dbo.Users 
where Age > 21;
select count(*) from dbo.Users 
where DownVotes < 1000;
select count(*) from dbo.Users 
where UpVotes > 1;
select count(*) from dbo.Users 
where (Location LIKE '%United Kingdom%' OR Location LIKE '%UK%')

create index age on dbo.users(age)


/* ****************************************************************************
NEXT EXERCISE: a while back, we found the one-and-done users: people who
created an account, but then never logged in again. Just out of curiosity, did
any of them earn reputation points in that one brief login? Design an index for
this query - but before you do, take a look at the plan it's using now, and the
number of logical reads it's doing:
*/

SELECT TOP 100 CreationDate, LastAccessDate, DisplayName, Reputation, Id
  FROM dbo.Users with (index=1)
  WHERE CreationDate = LastAccessDate
    AND Reputation <> 1
  ORDER BY Reputation DESC;
GO

SELECT TOP 100 CreationDate, LastAccessDate, DisplayName, Reputation, Id
  FROM dbo.Users
  WHERE CreationDate = LastAccessDate
    AND Reputation <> 1
  ORDER BY Reputation DESC;
GO
/* Huh. Interesting. Alright, your turn! Build the right index and prove it. */

create index Reputation on dbo.users(reputation)
include (CreationDate, LastAccessDate, DisplayName)