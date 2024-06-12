/*
Fundamentals of Index Tuning: JOIN Lab

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





DropIndexes;
GO
/* It leaves clustered indexes in place though. */


/* ****************************************************************************
THIS TIME, IT'S ALL YOU: you've learned a process, and now I'm going to leave
it to you to work through the process.

You have one commandment though: you're not allowed to index any >200 byte fields,
like NVARCHAR(500) or VARCHAR(500). Not allowed to use 'em as includes, either.

Here's your first query: find the users in Antarctica, and list their highly
upvoted comments sorted from newest to oldest.
*/

SELECT u.DisplayName, u.Location, 
    c.Score AS CommentScore, c.Text AS CommentText
  FROM dbo.Users u
  INNER JOIN dbo.Comments c ON u.Id = c.UserId
  WHERE u.Location = 'Antarctica'
    AND c.Score > 0
  ORDER BY c.CreationDate;
GO





/* ****************************************************************************
NEXT CHALLENGE: take that same list of Antarctica comments, but now I also want
to see the post that they commented on. I'm adding a join:
*/

SELECT u.DisplayName, u.Location, p.Title AS PostTitle, p.Id AS PostId,
    c.Score AS CommentScore, c.Text AS CommentText
  FROM dbo.Users u
  INNER JOIN dbo.Comments c ON u.Id = c.UserId
  INNER JOIN dbo.Posts p ON c.PostId = p.Id
  WHERE u.Location = 'Antarctica'
    AND c.Score > 0
  ORDER BY c.CreationDate;
GO
/* Want to see what post they commented on? You can add the PostId to this URL:
https://stackoverflow.com/questions/

So if you're looking for a Question with PostId = 923039, do this:
https://stackoverflow.com/questions/923039

You'll notice that some of them have null titles. I'll explain why in your next
challenge query below - but index for this one first.
*/






/* ****************************************************************************
NEXT CHALLENGE: in that Antarctica comment list, you probably noticed that some
of the PostTitles are null.

That's because at Stack, you can leave comments on both questions AND answers.
To see it in action, look at the comments on the questions & answers on this:
https://stackoverflow.com/questions/923039

So let's make our query a little more complex: I only want to see comments on
answers, and I want the results to have:
* The question title
* The person who posted the question
* The answer text
* The person who posted the answer
* The comment text

So my query looks like this:
*/
SELECT u.DisplayName, u.Location, 
    Question.Title AS QuestionTitle, Question.Id AS QuestionId, 
    QuestionUser.DisplayName AS QuestionUserDisplayName,
    Answer.Body AS AnswerBody, AnswerUser.DisplayName AS AnswerUserDisplayName,
    c.Score AS CommentScore, c.Text AS CommentText, c.CreationDate
  FROM dbo.Users u
  INNER JOIN dbo.Comments c ON u.Id = c.UserId
  INNER JOIN dbo.Posts Answer ON c.PostId = Answer.Id
  INNER JOIN dbo.PostTypes pt ON Answer.PostTypeId = pt.Id
  INNER JOIN dbo.Users AnswerUser ON Answer.OwnerUserId = AnswerUser.Id
  INNER JOIN dbo.Posts Question ON Answer.ParentId = Question.Id
  INNER JOIN dbo.Users QuestionUser ON Question.OwnerUserId = QuestionUser.Id
  WHERE u.Location = 'Antarctica'
    AND c.Score > 0
    AND pt.Type = 'Answer'
  ORDER BY c.CreationDate;
GO
/* Relax - it's not nearly as bad as it looks! */




/* ****************************************************************************
BONUS QUESTION: Hey, that wasn't so bad, was it? Let's just make one tiny change.

Instead of Antarctica, let's look for - oh I dunno, let's say...
*/
SELECT u.DisplayName, u.Location, 
    Question.Title AS QuestionTitle, Question.Id AS QuestionId, 
    QuestionUser.DisplayName AS QuestionUserDisplayName,
    Answer.Body AS AnswerBody, AnswerUser.DisplayName AS AnswerUserDisplayName,
    c.Score AS CommentScore, c.Text AS CommentText, c.CreationDate
  FROM dbo.Users u
  INNER JOIN dbo.Comments c ON u.Id = c.UserId
  INNER JOIN dbo.Posts Answer ON c.PostId = Answer.Id
  INNER JOIN dbo.PostTypes pt ON Answer.PostTypeId = pt.Id
  INNER JOIN dbo.Users AnswerUser ON Answer.OwnerUserId = AnswerUser.Id
  INNER JOIN dbo.Posts Question ON Answer.ParentId = Question.Id
  INNER JOIN dbo.Users QuestionUser ON Question.OwnerUserId = QuestionUser.Id
  WHERE u.Location = 'United States'
    AND c.Score > 0
    AND pt.Type = 'Answer'
  ORDER BY c.CreationDate;
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