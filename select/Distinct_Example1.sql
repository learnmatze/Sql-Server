--Example 1: Retrieve the Distinct Product Categories in AdventureWorks.

-- SQL Query to retrieve distinct product categories
SELECT DISTINCT
    pc.Name AS ProductCategory
FROM 
    Production.ProductCategory AS pc;
