use StackOverflow2010
go

select top 100 * from users

select id from users

SELECT compatibility_level
FROM sys.databases
WHERE name = 'StackOverflow2010';

ALTER DATABASE StackOverflow2010
SET COMPATIBILITY_LEVEL = 150; -- Change the value to the desired compatibility level

-- Query to retrieve the cost threshold for parallelism setting
SELECT value 
FROM sys.configurations 
WHERE name = 'cost threshold for parallelism';

-- Query to retrieve the MAXDOP setting
SELECT value 
FROM sys.configurations 
WHERE name = 'max degree of parallelism';

--users table
select id from
users



use StackOverflow2010;

set statistics io on;
--set statistics time on;
go
select id 
from users;

select id
from users
where LastAccessDate > '2014-07-01'

set statistics io on;
--set statistics time off;
go
select id
from users
where LastAccessDate > '2014-07-01'
order by LastAccessDate

set statistics io on;
--set statistics time on;
go
select *
from users
where LastAccessDate > '2014-07-01'
order by LastAccessDate
go 5

create nonclustered index
IX_LastAccessDate_ID
on users(LastAccessDate, Id)
go

update users 
set age = age + 1
where DisplayName = 'Brent Ozar'

select id
from users
where LastAccessDate > '2014-07-01'
order by LastAccessDate

select *
from users
where LastAccessDate > '2014-07-01'
order by LastAccessDate

set statistics io on;
go
set statistics time on;
go
select id
from users with(index=1)
where LastAccessDate > '2014-07-01'
order by LastAccessDate

select id
from users
where LastAccessDate > '2014-07-01'
order by LastAccessDate

select id
from users
where LastAccessDate > '1800-01-01'
order by LastAccessDate

select top 10 *
from users

select id, DisplayName, Age
from Users
where LastAccessDate > '2014-07-01'
order by LastAccessDate

select id, DisplayName, Age
from Users
where LastAccessDate > '2024-07-01'
order by LastAccessDate

select id, DisplayName, Age
from Users
where LastAccessDate > '2014-07-01'
order by LastAccessDate

select id, DisplayName, Age
from Users with (INDEX=IX_LastAccessDate_Id)
where LastAccessDate > '2014-07-01'
order by LastAccessDate

dbcc show_statistics('Users', 'IX_LastAccessDate_Id')
go

select id, displayname, age
from users
where LastAccessDate >= '2014/07/01'
and LastAccessDate < '2014/08/01'
order by LastAccessDate

select id, displayname, age
from users
where year(LastAccessDate) = 2014
and month(LastAccessDate) = 7
order by LastAccessDate


select id, displayname, age
from users
where year(LastAccessDate) = 2014
and month(LastAccessDate) = 7
order by LastAccessDate

select id, displayname, age
from users with (index = IX_LastAccessDate_Id)
where year(LastAccessDate) = 2014
and month(LastAccessDate) = 7
order by LastAccessDate

create nonclustered index IX_LastAccessDate_id_DisplayName_Age
on Users(LastAccessDate, Id, DisplayName, Age)

sp_blitzindex @TableName = 'Users'

create nonclustered index IX_LastAccessDate_id_DisplayName_Age_includes
on Users(LastAccessDate, Id)
include(DisplayName, Age)


create nonclustered index IX_Reputation on dbo.Users(Reputation);
go
dbcc show_statistics('Users', 'IX_Reputation')
go
DROP INDEX IX_Reputation ON Users;
go

create nonclustered index IX_Displayname on dbo.Users(DisplayName);
go
dbcc show_statistics('Users', 'IX_Displayname')
go
DROP INDEX IX_Displayname ON Users;
go

dbo.sp_BlitzIndex @Tablename = 'Users'

sp_Blitz