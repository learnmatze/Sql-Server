--Example 1: Retrieve the Top 5 Products by Sales Quantity in AdventureWorks.

-- SQL Query to retrieve the top 5 products by sales quantity
SELECT TOP 5
    p.Name AS ProductName,
    p.ProductNumber,
    SUM(sod.OrderQty) AS TotalSalesQuantity
FROM 
    Production.Product AS p
JOIN 
    Sales.SalesOrderDetail AS sod ON p.ProductID = sod.ProductID
GROUP BY 
    p.ProductID, p.Name, p.ProductNumber
ORDER BY 
    TotalSalesQuantity DESC;
