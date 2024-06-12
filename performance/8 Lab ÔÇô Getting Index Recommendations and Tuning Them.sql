/*
Fundamentals of Index Tuning: Improving the Built-In Index Recommendations

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



/* This stored procedure drops all nonclustered indexes: */
DropIndexes;
GO
/* It leaves clustered indexes in place though. */


SET STATISTICS IO, TIME OFF;
GO
/* Which badges are earned most often by people from Antarctica? */
SELECT b.Name, COUNT(*) AS BadgesEarned
  FROM dbo.Users u
  INNER JOIN dbo.Badges b ON u.Id = b.UserId
  WHERE u.Location = 'Antarctica'
    AND b.Date BETWEEN '2008/01/01' AND '2008/12/31'
  GROUP BY b.Name
  ORDER BY COUNT(*) DESC;

/* Who has earned the rarest badges? */
WITH RarestBadges AS (SELECT TOP 100 rare.Name, COUNT(*) AS BadgesEarned
                        FROM dbo.Badges rare
                        GROUP BY rare.Name
                        ORDER BY COUNT(*))
SELECT r.Name AS BadgeName, r.BadgesEarned PeopleWhoEarnedIt, u.DisplayName, u.Location, u.Reputation, u.Id AS UserId
  FROM RarestBadges r
  INNER JOIN dbo.Badges b ON r.Name = b.Name
  INNER JOIN dbo.Users u ON b.UserId = u.Id
  ORDER BY r.BadgesEarned, r.Name, u.DisplayName;

/* What are the highest-scored SQL Server questions? */
SELECT TOP 100 p.Score, p.Title, p.Tags, p.ViewCount
  FROM dbo.Posts p
  INNER JOIN dbo.PostTypes pt ON p.PostTypeId = pt.Id
  WHERE pt.Type = 'Question'
    AND p.Tags LIKE '%<sql-server>%'
  ORDER BY p.Score DESC;

/* Who posts the most zero-score SQL Server questions? */
SELECT TOP 100 u.DisplayName, u.Location, u.Id, COUNT(*) AS Recs
  FROM dbo.Posts p
  INNER JOIN dbo.PostTypes pt ON p.PostTypeId = pt.Id
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE p.Score = 0
    AND pt.Type = 'Question'
    AND p.Tags LIKE '%<sql-server>%'
  GROUP BY u.DisplayName, u.Location, u.Id
  ORDER BY COUNT(*) DESC;

/* Awww, poor Gopal. Let's see what he asked: */
SELECT *
  FROM dbo.Posts
  WHERE OwnerUserId = 128071
    AND Score = 0
    AND Tags LIKE '%<sql-server>%';

/* Ouch, SQL Server 2000. Yeah, that explains that. 
   Do questions about newer versions perform better than older ones? 
   (If you're using the Stack 2010 export, your case statement can be short.) */
SELECT SQLServerVersion = CASE 
            WHEN Tags LIKE '%<sql-server-2012>%' THEN 'SQL Server 2012' 
            WHEN Tags LIKE '%<sql-server-2008-r2>%' THEN 'SQL Server 2008 R2'
            WHEN Tags LIKE '%<sql-server-2008>%' THEN 'SQL Server 2008'
            WHEN Tags LIKE '%<sql-server-2005>%' THEN 'SQL Server 2005'
            WHEN Tags LIKE '%<sql-server-2000>%' THEN 'SQL Server 2000'
            ELSE 'Not About SQL Server'
            END,
    COUNT(*) AS Questions, AVG(Score * 1.0) AS AvgScore, 
    AVG(AnswerCount * 1.0) AS AvgAnswers, AVG(CommentCount * 1.0) AS AvgComments
  FROM dbo.Posts
  WHERE Score IS NOT NULL
    AND Tags LIKE '%<sql-server%'
    AND PostTypeId = 1
  GROUP BY CASE 
            WHEN Tags LIKE '%<sql-server-2012>%' THEN 'SQL Server 2012' 
            WHEN Tags LIKE '%<sql-server-2008-r2>%' THEN 'SQL Server 2008 R2'
            WHEN Tags LIKE '%<sql-server-2008>%' THEN 'SQL Server 2008'
            WHEN Tags LIKE '%<sql-server-2005>%' THEN 'SQL Server 2005'
            WHEN Tags LIKE '%<sql-server-2000>%' THEN 'SQL Server 2000'
            ELSE 'Not About SQL Server'
            END;

/* Where are people earning the SQL Server badge from? */
SELECT u.Location, COUNT(DISTINCT u.Id) AS BadgeEarnersInThisLocation
  FROM dbo.Badges b
  INNER JOIN dbo.Users u ON b.UserId = u.Id
  WHERE b.Name = 'sql-server'
  GROUP BY u.Location
  ORDER BY COUNT(DISTINCT u.Id) DESC;

/* What is the most popular first word in Stack Overflow questions? */
SELECT TOP 100 
    SUBSTRING(p.Title, 1, CHARINDEX(' ', p.Title)) AS FirstWord,
    COUNT(DISTINCT p.Id) AS Questions, AVG(Score * 1.0) AS AvgScore,
    AVG(CommentCount * 1.0) AS AvgCommentCount, AVG(AnswerCount * 1.0) AS AvgAnswerCount,
    AVG(ViewCount * 1.0) AS AvgViewCount
  FROM dbo.Posts p
  WHERE p.PostTypeId = 1
    AND CHARINDEX(' ', p.Title) > 0
  GROUP BY SUBSTRING(p.Title, 1, CHARINDEX(' ', p.Title))
  ORDER BY COUNT(DISTINCT p.Id) DESC;

/* Is there one location that casts higher-bounty votes than others? */
SELECT u.Location, AVG(v.BountyAmount * 1.0), COUNT(DISTINCT v.Id) AS BountiesPosted
  FROM dbo.Votes v
  INNER JOIN dbo.Users u ON v.UserId = u.Id
  WHERE v.BountyAmount > 0
  GROUP BY u.Location
  HAVING COUNT(DISTINCT v.Id) > 1
  ORDER BY AVG(v.BountyAmount * 1.0) DESC;

/* Whoa - who's posting those high bounties? */
SELECT TOP 100 v.BountyAmount, u.DisplayName, u.Location, 
    p.Title AS QuestionTitle, p.Id AS QuestionId, p.Tags
  FROM dbo.Votes v
  INNER JOIN dbo.Users u ON v.UserId = u.Id
  INNER JOIN dbo.Posts p ON v.PostId = p.Id
  ORDER BY v.BountyAmount DESC;

/* Ah, 550 was the max bounty amount: 
https://meta.stackexchange.com/questions/45809/what-was-the-highest-bounty-ever-posted

Which brings an interesting question: who got cheap, and posted LESS than the
500 point bounty, but still high bounties? */
SELECT TOP 100 v.BountyAmount, u.DisplayName, u.Location, 
    p.Title AS QuestionTitle, p.Id AS QuestionId, p.Tags
  FROM dbo.Votes v
  INNER JOIN dbo.Users u ON v.UserId = u.Id
  INNER JOIN dbo.Posts p ON v.PostId = p.Id
  WHERE v.BountyAmount < 500
  ORDER BY v.BountyAmount DESC;
GO 25




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