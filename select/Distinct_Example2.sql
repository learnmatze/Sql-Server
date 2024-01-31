--Example 2: Retrieve Distinct Employees by Job Title in AdventureWorks.

-- SQL Query to retrieve distinct employees by job title
SELECT DISTINCT
    e.JobTitle,
    e.FirstName + ' ' + e.LastName AS EmployeeName
FROM 
    HumanResources.Employee AS e;
