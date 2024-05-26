use AdventureWorks2019
go

--extened pages
-- Small Data Example:
  CREATE TABLE ExampleTable (
      ID int PRIMARY KEY,
      SmallData nvarchar(max)
  );

  INSERT INTO ExampleTable (ID, SmallData)
  VALUES (1, N'This is a short string');

-- Large Data Example:
  CREATE TABLE ExampleTable (
      ID int PRIMARY KEY,
      LargeData nvarchar(max)
  );
  INSERT INTO ExampleTable (ID, LargeData)
  VALUES (1, REPLICATE(N'A', 5000)); -- This is 5000 characters, which is 10000 bytes

SELECT object_name(dt.object_id) Tablename,si.name
IndexName,dt.avg_fragmentation_in_percent AS
ExternalFragmentation,dt.avg_page_space_used_in_percent AS
InternalFragmentation
FROM
(
    SELECT object_id,index_id,avg_fragmentation_in_percent,avg_page_space_used_in_percent
    FROM sys.dm_db_index_physical_stats (db_id('AdventureWorks2019'),null,null,null,'DETAILED')
	WHERE index_id <> 0
) AS dt INNER JOIN sys.indexes si ON si.object_id=dt.object_id
AND si.index_id=dt.index_id 
ORDER BY avg_fragmentation_in_percent DESC

use St
go

SELECT object_name(dt.object_id) Tablename,si.name
IndexName,dt.avg_fragmentation_in_percent AS
ExternalFragmentation,dt.avg_page_space_used_in_percent AS
InternalFragmentation
FROM
(
    SELECT object_id,index_id,avg_fragmentation_in_percent,avg_page_space_used_in_percent
    FROM sys.dm_db_index_physical_stats (db_id('AdventureWorks2019'),null,null,null,'DETAILED')
	WHERE index_id <> 0
) AS dt INNER JOIN sys.indexes si ON si.object_id=dt.object_id
AND si.index_id=dt.index_id 
AND si.index_id=dt.index_id AND dt.avg_fragmentation_in_percent>10
AND dt.avg_page_space_used_in_percent<75
ORDER BY avg_fragmentation_in_percent DESC

use StackOverflow2010

DBCC SHOW_STATISTICS('Users', 'Age');

sp_help Users

DBCC SHOW_STATISTICS('Users', 'IX_Location_WebsiteUrl_Includes')

DBCC SHOW_STATISTICS ('Users', 'Age') WITH HISTOGRAM;

drop table Products

CREATE TABLE Products (
    ProductID INT IDENTITY(1,1),
    ProductName VARCHAR(50) NOT NULL,
    Category VARCHAR(20) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL
);

CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(50) NOT NULL,
    Category VARCHAR(20) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL
);

-- Generate sample data
DECLARE @Counter INT = 1;
DECLARE @Category VARCHAR(20);
DECLARE @ProductName VARCHAR(50);
DECLARE @Price DECIMAL(10,2);
DECLARE @Quantity INT;

WHILE @Counter <= 1000
BEGIN
    SET @Category = CASE WHEN @Counter % 10 = 0 THEN 'Electronics'
                         WHEN @Counter % 10 = 1 THEN 'Books'
                         WHEN @Counter % 10 = 2 THEN 'Clothing'
                         WHEN @Counter % 10 = 3 THEN 'Sports'
                         ELSE 'Other'
                    END;
    SET @ProductName = 'Product ' + CAST(@Counter AS VARCHAR(10));
    SET @Price = RAND() * 100;
    SET @Quantity = FLOOR(RAND() * 1000);
    INSERT INTO Products (ProductName, Category, Price, Quantity)
    VALUES (@ProductName, @Category, @Price, @Quantity);
    SET @Counter += 1;
END;

--Check indexes
SELECT i.name AS IndexName, i.type_desc AS IndexType, c.name AS ColumnName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.column_id = c.column_id AND ic.object_id = c.object_id
WHERE i.object_id = OBJECT_ID('dbo.Products')
ORDER BY i.name, ic.index_column_id;

CREATE CLUSTERED INDEX IX_Products_ProductID ON Products (ProductID);

--Check indexes
SELECT i.name AS IndexName, i.type_desc AS IndexType, c.name AS ColumnName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.column_id = c.column_id AND ic.object_id = c.object_id
WHERE i.object_id = OBJECT_ID('dbo.Products')
ORDER BY i.name, ic.index_column_id;

CREATE NONCLUSTERED INDEX IX_Products_Category ON Products (Category);

CREATE NONCLUSTERED INDEX IX_Products_ProductName ON Products (ProductName);

SELECT i.name AS IndexName, i.type_desc AS IndexType, c.name AS ColumnName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.column_id = c.column_id AND ic.object_id = c.object_id
WHERE i.object_id = OBJECT_ID('dbo.Products')
ORDER BY i.name, ic.index_column_id;

-- Generate sample data
DECLARE @Counter INT = 1;
DECLARE @Category VARCHAR(20);
DECLARE @ProductName VARCHAR(50);
DECLARE @Price DECIMAL(10,2);
DECLARE @Quantity INT;

WHILE @Counter <= 1000
BEGIN
    SET @Category = CASE WHEN @Counter % 10 = 0 THEN 'Electronics'
                         WHEN @Counter % 10 = 1 THEN 'Books'
                         WHEN @Counter % 10 = 2 THEN 'Clothing'
                         WHEN @Counter % 10 = 3 THEN 'Sports'
                         ELSE 'Other'
                    END;
    SET @ProductName = 'Product ' + CAST(@Counter AS VARCHAR(10));
    SET @Price = RAND() * 100;
    SET @Quantity = FLOOR(RAND() * 1000);

    INSERT INTO Products (ProductName, Category, Price, Quantity)
    VALUES (@ProductName, @Category, @Price, @Quantity);

    SET @Counter += 1;
END;

select * from Products

CREATE STATISTICS ST_Products_Category ON dbo.Products (Category);

CREATE STATISTICS ST_Products_ProductName ON dbo.Products (ProductName);

CREATE STATISTICS ST_Products_Price ON dbo.Products (Price);

DBCC SHOW_STATISTICS ('dbo.Products', 'ST_Products_Category') --WITH HISTOGRAM

DBCC SHOW_STATISTICS ('dbo.Products', 'ST_Products_ProductName') --WITH HISTOGRAM

DBCC SHOW_STATISTICS ('dbo.Products', 'ST_Products_Price') --WITH HISTOGRAM

select * from Products
CREATE STATISTICS ST_Products_Category ON dbo.Products (Category);
CREATE STATISTICS ST_Products_ProductName ON dbo.Products (ProductName);
DBCC SHOW_STATISTICS ('dbo.Products', 'ST_Products_Category') --WITH HISTOGRAM
DBCC SHOW_STATISTICS ('dbo.Products', 'ST_Products_ProductName') --WITH HISTOGRAM
DBCC SHOW_STATISTICS ('dbo.Products', 'ST_Products_Price') --WITH HISTOGRAM

--The output will show details about the histogram buckets:
--* including the bucket boundaries (RANGE_HI_KEY), 
--* the number of rows in each bucket (RANGE_ROWS), 
--* the number of rows with the same value as the bucket boundary (EQ_ROWS), 
--* the number of distinct values in each bucket (DIST_RANGE_ROWS), 
--* the average number of duplicate rows in each bucket (AVG_RANGE_ROWS).