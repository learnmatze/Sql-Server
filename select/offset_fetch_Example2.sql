--Example 2: Retrieve Employees with Pagination in AdventureWorks.

-- SQL Query to retrieve employees with pagination
SELECT
    BusinessEntityID,
    FirstName,
    LastName,
    JobTitle,
    HireDate
FROM 
    HumanResources.Employee
ORDER BY 
    BusinessEntityID
OFFSET 5 ROWS
FETCH NEXT 5 ROWS ONLY;

