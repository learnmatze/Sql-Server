/*
How Are Missing Index Hints Built?

Here's what you're going to learn in this demo:

* How SQL Server picks missing index column order
* What SQL Server doesn't consider: selectivity or statistics

This demo requires:

* Any supported version of SQL Server or Azure SQL DB
  (although the 10M row table creation can be pretty slow in Azure)

Make sure we won't have trivial queries that won't generate index requests:
*/
EXEC sys.sp_configure N'cost threshold for parallelism', N'5'
GO
RECONFIGURE
GO


/* Let's create a table with a few columns, and insert 100,000 identical rows: */
--DROP TABLE dbo.DiningRoom;


CREATE TABLE dbo.DiningRoom
  (FirstColumn INT,
   SecondColumn INT,
   ThirdColumn INT,
   FourthColumn INT,
   FifthColumn INT,
   SixthColumn INT
   );
INSERT INTO dbo.DiningRoom 
  (FirstColumn, SecondColumn, ThirdColumn, FourthColumn, FifthColumn, SixthColumn)
  SELECT TOP 10000000 1, 1, 1, 1, 1, 1
  FROM sys.all_columns ac1
  CROSS JOIN sys.all_columns ac2
  CROSS JOIN sys.all_columns ac3;
GO
SELECT TOP 100 * FROM dbo.DiningRoom;
GO

/* Turn on actual execution plans, and check the missing index requests: */
SET STATISTICS TIME, IO ON;
GO
SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn = 0;

SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE SecondColumn = 0;
GO



/* Simple so far. Now let's try two columns: */
SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn = 0
    AND SecondColumn = 0;

SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE SecondColumn = 0
    AND FirstColumn = 0;
GO

/* 
/poll "What missing index recommendations will we get?" "SQL will ask for two different indexes" "Both will ask for FirstColumn, SecondColumn" "Both will ask for SecondColumn, FirstColumn"  anonymous

*/


/* 
What about selectivity?
If our where clause looks for one thing that doesn't exist, and one thing that
does, will SQL Server put the thing that doesn't exist first so it's faster?
*/
SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn = 1
    AND SecondColumn = 0;

SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn = 0
    AND SecondColumn = 1;
GO
/* 
/poll "Now what missing index recommendations will we get?" "SQL will ask for two different indexes" "Both will ask for FirstColumn, SecondColumn" "Both will ask for SecondColumn, FirstColumn"  anonymous

*/




/* 
TAKEAWAY #1:
missing index column order is determined by column order in the table.

It's kinda disappointing, but at least there's a little more logic than that.
And I know what you're thinking: selectivity matters, right? Wrong.
*/



/* Next, instead of equality searches ( = ), try inequality ( <> ).*/
SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn <> 1
    AND SecondColumn <> 1;

SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE SecondColumn <> 1
    AND FirstColumn <> 1;
GO


/* Still the same: FirstColumn, SecondColumn.

But now try equality on one field, inequality on the other:
*/
SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn = 1    /* EQUALITY */
    AND SecondColumn <> 1; /* INEQUALITY */ 

SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn <> 1   /* INEQUALITY */
    AND SecondColumn = 1;  /* EQUALITY */
GO


/* 
TAKEAWAY #2:
Equality searches go first
Inequality searches go second.

To see the difference, look in the execution plan XML, and you'll see the
equality searches are listed first, then the inequality searches.
*/



/* Another example of inequality vs equality: */
SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn IS NULL       /* EQUALITY */
    AND SecondColumn IS NOT NULL; /* INEQUALITY */ 

SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn IS NOT NULL   /* INEQUALITY */
    AND SecondColumn IS NULL;     /* EQUALITY */
GO



/* 
So it works like this:
Equality searched fields, in the order that the columns appear in the table
Inequality searched fields, ditto



So now it's your turn.
Without running the query, GUESS the index recommendation orders:
*/
SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE ThirdColumn = 0
    AND FourthColumn <> 1;
GO
/* 
/poll "What will be the missing index recommendation?" "ThirdColumn, FourthColumn" "FourthColumn, ThirdColumn" "Something else"  anonymous

*/

SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FourthColumn <> 1
    AND SecondColumn = 0;
GO
/* 
/poll "What will be the missing index recommendation?" "SecondColumn, FourthColumn" "FourthColumn, SecondColumn" "Something else"  anonymous

*/


/* Advanced test: guess the order of these: */
SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn <> SecondColumn;
GO
/* 
/poll "What will be the missing index recommendation?" "FirstColumn, SecondColumn" "SecondColumn, FirstColumn" "Something else"  anonymous

*/
  
SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FourthColumn = 0
    AND FirstColumn <> 0
    AND ThirdColumn = 0;
GO
/* 
/poll "What will be the missing index recommendation?" "FirstColumn, ThirdColumn, FourthColumn" "ThirdColumn, FourthColumn, FirstColumn" "FourthColumn, FirstColumn, ThirdColumn" "Something else"  anonymous

*/
	
SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn <> 0
    AND SecondColumn IS NULL
    AND FourthColumn IS NOT NULL
    AND ThirdColumn = 1;
GO





/* 
This isn't just about execution plan hints, either: the same logic drives
the missing index recommendations in the DMVs. Run a few queries to generate
missing indexes:

Turn off execution plans first, then:
*/
SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn = 0
    AND SecondColumn = 0; /* BOTH EQUALITY */

SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn <> 1
    AND SecondColumn <> 1; /* BOTH INEQUALITY */

SELECT 'Hi Mom!'
  FROM dbo.DiningRoom
  WHERE FirstColumn = 0
    AND SecondColumn <> 0; /* MIXED */

GO 10


/* And check the missing index DMVs: */
sp_BlitzIndex @TableName = 'DiningRoom'


/* 
SQL Server will recommend 3 similar indexes on FirstColumn, SecondColumn.
We're not doing any kind of advanced de-duping in sp_BlitzIndex: index tuning
still involves manual intervention to figure out which field should really
go first.

But now that you know the trick, you can do a better job of interpreting
real-life recommendations.

To learn more about how this works:

How does SQL Server determine key column order in missing index requests?
https://dba.stackexchange.com/questions/208947/
Shout out to Bryan Rebok for figuring this out!
*/
DROP TABLE dbo.DiningRoom;









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