/*
Fundamentals of Index Tuning: JOIN Clauses

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

/* Get the estimated plan: */
SELECT u.DisplayName, c.CreationDate, c.Text
  FROM dbo.Users u
  INNER JOIN dbo.Comments c
    ON u.Id = c.UserId;
GO



/* Let's try a more realistic query first: */
SELECT u.DisplayName, c.CreationDate, c.Text
  FROM dbo.Users u
  INNER JOIN dbo.Comments c
    ON u.Id = c.UserId
  WHERE u.DisplayName = 'Brent Ozar'
GO
/* Do we need an index on Users? On what fields?
   Do we need an index on Comments? On what fields?
*/

CREATE INDEX IX_DisplayName ON dbo.Users(DisplayName);
CREATE INDEX IX_UserId ON dbo.Comments(UserId);
GO

/* Then try again. Does the query use our indexes? */
SELECT u.DisplayName, c.CreationDate, c.Text
  FROM dbo.Users u
  INNER JOIN dbo.Comments c
    ON u.Id = c.UserId
  WHERE u.DisplayName = 'Brent Ozar';
GO


/* Getting a little more complex: */
SELECT u.DisplayName, c.CreationDate, c.Text
  FROM dbo.Users u
  INNER JOIN dbo.Comments c
    ON u.Id = c.UserId
  WHERE u.DisplayName = 'Brent Ozar'
  ORDER BY c.CreationDate;
GO


/* Does a separate index on CreationDate help? */
CREATE INDEX IX_CreationDate ON dbo.Comments(CreationDate);
GO
SELECT u.DisplayName, c.CreationDate, c.Text
  FROM dbo.Users u
  INNER JOIN dbo.Comments c
    ON u.Id = c.UserId
  WHERE u.DisplayName = 'Brent Ozar'
  ORDER BY c.CreationDate;
GO


/* What if we widen up the index on UserId, CreationDate? */
CREATE INDEX IX_UserId_CreationDate ON dbo.Comments(UserId, CreationDate);
GO
SELECT u.DisplayName, c.CreationDate, c.Text
  FROM dbo.Users u
  INNER JOIN dbo.Comments c
    ON u.Id = c.UserId
  WHERE u.DisplayName = 'Brent Ozar'
  ORDER BY c.CreationDate;
GO


/* To understand why, use a different user name and show the User.Id: */
SELECT u.DisplayName, u.Id, c.CreationDate, c.Text
  FROM dbo.Users u
  INNER JOIN dbo.Comments c
    ON u.Id = c.UserId
  WHERE u.DisplayName = 'JamesBrownIsDead'
  ORDER BY c.CreationDate;
GO





DropIndexes;
GO



/* Does it matter where we put filters, the JOIN or the WHERE? */
SELECT u.DisplayName, u.Id, c.CreationDate, c.Text
  FROM dbo.Users u
  INNER JOIN dbo.Comments c
                ON u.Id = c.UserId
                AND c.Score > 0
  WHERE u.DisplayName = 'JamesBrownIsDead'
  ORDER BY c.CreationDate;

SELECT u.DisplayName, u.Id, c.CreationDate, c.Text
  FROM dbo.Users u
  INNER JOIN dbo.Comments c
                ON u.Id = c.UserId
  WHERE u.DisplayName = 'JamesBrownIsDead'
    AND c.Score > 0
  ORDER BY c.CreationDate;
GO







DropIndexes;
GO
SELECT Question.Id AS QuestionId, Question.Title, Answer.Body, c.Text, c.Score
  FROM dbo.Users u
    INNER JOIN dbo.Comments c ON u.Id = c.UserId
    INNER JOIN dbo.Posts Answer ON c.PostId = Answer.Id
    INNER JOIN dbo.Posts Question ON Answer.ParentId = Question.Id
  WHERE u.DisplayName = 'Brent Ozar'
    AND Question.Title LIKE 'SQL Queries%';
GO

SELECT COUNT(*) FROM dbo.Users WHERE DisplayName = 'Brent Ozar';
SELECT COUNT(*) FROM dbo.Posts WHERE Title LIKE 'SQL Queries%';
GO




/* Try rewriting the query in the opposite order, with Questions first. */
SELECT Question.Id AS QuestionId, Question.Title, Answer.Body, c.Text, c.Score
  FROM dbo.Posts Question
    INNER JOIN dbo.Posts Answer ON Question.Id = Answer.ParentId
    INNER JOIN dbo.Comments c ON Answer.Id = c.PostId
    INNER JOIN dbo.Users u ON c.UserId = U.Id
  WHERE Question.Title LIKE 'SQL Queries%'
    AND u.DisplayName = 'Brent Ozar';
GO

CREATE INDEX IX_Title ON dbo.Posts(Title);
GO

/* Does that change which table gets processed first? */
SELECT Question.Id AS QuestionId, Question.Title, Answer.Body, c.Text, c.Score
  FROM dbo.Posts Question
    INNER JOIN dbo.Posts Answer ON Question.Id = Answer.ParentId
    INNER JOIN dbo.Comments c ON Answer.Id = c.PostId
    INNER JOIN dbo.Users u ON c.UserId = U.Id
  WHERE Question.Title LIKE 'SQL Queries%'
    AND u.DisplayName = 'Brent Ozar';
GO



CREATE INDEX IX_UserId ON dbo.Comments(UserId);
GO
SELECT Question.Id AS QuestionId, Question.Title, Answer.Body, c.Text, c.Score
  FROM dbo.Posts Question
    INNER JOIN dbo.Posts Answer ON Question.Id = Answer.ParentId
    INNER JOIN dbo.Comments c ON Answer.Id = c.PostId
    INNER JOIN dbo.Users u ON c.UserId = U.Id
  WHERE Question.Title LIKE 'SQL Queries%'
    AND u.DisplayName = 'Brent Ozar';
GO



CREATE INDEX IX_DisplayName ON dbo.Users(DisplayName);
GO
SELECT Question.Id AS QuestionId, Question.Title, Answer.Body, c.Text, c.Score
  FROM dbo.Posts Question
    INNER JOIN dbo.Posts Answer ON Question.Id = Answer.ParentId
    INNER JOIN dbo.Comments c ON Answer.Id = c.PostId
    INNER JOIN dbo.Users u ON c.UserId = U.Id
  WHERE Question.Title LIKE 'SQL Queries%'
    AND u.DisplayName = 'Brent Ozar';
GO






DropIndexes;
GO

SELECT *
  FROM dbo.Users u
  WHERE u.Location = 'Antarctica'
  AND EXISTS (SELECT * FROM dbo.Comments c WHERE u.Id = c.UserId);
GO

CREATE INDEX IX_UserId ON dbo.Comments(UserId);
GO
SELECT *
  FROM dbo.Users u
  WHERE u.Location = 'Antarctica'
  AND EXISTS (SELECT * FROM dbo.Comments c WHERE u.Id = c.UserId);
GO

CREATE INDEX IX_Location ON dbo.Users(Location);
GO
SELECT *
  FROM dbo.Users u
  WHERE u.Location = 'Antarctica'
  AND EXISTS (SELECT * FROM dbo.Comments c WHERE u.Id = c.UserId);
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