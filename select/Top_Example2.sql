--Example 2: Retrieve the Top 10 Customers by Total Purchases in AdventureWorks.

-- SQL Query to retrieve the top 10 customers by total purchases
SELECT TOP 10
    c.CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    SUM(so.TotalDue) AS TotalPurchases
FROM 
    Sales.Customer AS c
JOIN 
    Sales.SalesOrderHeader AS so ON c.CustomerID = so.CustomerID
GROUP BY 
    c.CustomerID, c.FirstName, c.LastName
ORDER BY 
    TotalPurchases DESC;

