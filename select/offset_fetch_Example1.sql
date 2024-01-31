--Example 1: Retrieve Products with Pagination in AdventureWorks.

-- SQL Query to retrieve products with pagination
SELECT
    ProductID,
    Name,
    ProductNumber,
    StandardCost,
    ListPrice
FROM 
    Production.Product
ORDER BY 
    ProductID
OFFSET 10 ROWS
FETCH NEXT 10 ROWS ONLY;
