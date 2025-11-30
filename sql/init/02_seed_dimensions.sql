USE Warehouse;
SET NOCOUNT ON;

-- Channels
IF NOT EXISTS (SELECT 1 FROM dbo.DimChannel WHERE ChannelName = N'Online')
    INSERT INTO dbo.DimChannel(ChannelName) VALUES (N'Online');
IF NOT EXISTS (SELECT 1 FROM dbo.DimChannel WHERE ChannelName = N'Store')
    INSERT INTO dbo.DimChannel(ChannelName) VALUES (N'Store');
IF NOT EXISTS (SELECT 1 FROM dbo.DimChannel WHERE ChannelName = N'Reseller')
    INSERT INTO dbo.DimChannel(ChannelName) VALUES (N'Reseller');
IF NOT EXISTS (SELECT 1 FROM dbo.DimChannel WHERE ChannelName = N'Marketplace')
    INSERT INTO dbo.DimChannel(ChannelName) VALUES (N'Marketplace');

-- Regions (US-focused)
;WITH Regions AS (
  SELECT * FROM (VALUES
    (N'USA',N'NY',N'New York',N'Northeast'),
    (N'USA',N'CA',N'Los Angeles',N'West'),
    (N'USA',N'IL',N'Chicago',N'Midwest'),
    (N'USA',N'TX',N'Houston',N'South'),
    (N'USA',N'AZ',N'Phoenix',N'West'),
    (N'USA',N'PA',N'Philadelphia',N'Northeast'),
    (N'USA',N'TX',N'Dallas',N'South'),
    (N'USA',N'CA',N'San Diego',N'West'),
    (N'USA',N'CA',N'San Jose',N'West'),
    (N'USA',N'FL',N'Miami',N'South'),
    (N'USA',N'GA',N'Atlanta',N'South'),
    (N'USA',N'MA',N'Boston',N'Northeast'),
    (N'USA',N'WA',N'Seattle',N'West'),
    (N'USA',N'CO',N'Denver',N'West'),
    (N'USA',N'MI',N'Detroit',N'Midwest'),
    (N'USA',N'MN',N'Minneapolis',N'Midwest'),
    (N'USA',N'OH',N'Columbus',N'Midwest'),
    (N'USA',N'NC',N'Charlotte',N'South'),
    (N'USA',N'DC',N'Washington',N'Northeast'),
    (N'USA',N'OR',N'Portland',N'West'),
    (N'USA',N'UT',N'Salt Lake City',N'West'),
    (N'USA',N'MO',N'St. Louis',N'Midwest'),
    (N'USA',N'TN',N'Nashville',N'South'),
    (N'USA',N'MD',N'Baltimore',N'Northeast'),
    (N'USA',N'IN',N'Indianapolis',N'Midwest'),
    (N'USA',N'WI',N'Milwaukee',N'Midwest'),
    (N'USA',N'NV',N'Las Vegas',N'West'),
    (N'USA',N'NJ',N'Newark',N'Northeast'),
    (N'USA',N'LA',N'New Orleans',N'South'),
    (N'USA',N'PA',N'Pittsburgh',N'Northeast')
  ) AS r(Country, StateProvince, City, RegionGroup)
)
MERGE dbo.DimRegion AS tgt
USING Regions AS src
  ON tgt.Country = src.Country AND tgt.StateProvince = src.StateProvince AND tgt.City = src.City
WHEN NOT MATCHED BY TARGET THEN
  INSERT (Country, StateProvince, City, RegionGroup)
  VALUES (src.Country, src.StateProvince, src.City, src.RegionGroup)
WHEN MATCHED THEN
  UPDATE SET RegionGroup = src.RegionGroup;

-- Products: build from items x brands with price variance
;WITH Items AS (
  SELECT N'Electronics' AS Category, N'Phones' AS Subcategory, N'Smartphone' AS ItemName, CAST(699.00 AS decimal(10,2)) AS BasePrice UNION ALL
  SELECT N'Electronics', N'Computers', N'Laptop', 1099.00 UNION ALL
  SELECT N'Electronics', N'Audio', N'Headphones', 149.00 UNION ALL
  SELECT N'Electronics', N'Displays', N'Monitor', 299.00 UNION ALL
  SELECT N'Electronics', N'Tablets', N'Tablet', 399.00 UNION ALL
  SELECT N'Electronics', N'Wearables', N'Smartwatch', 249.00 UNION ALL
  SELECT N'Home & Kitchen', N'Appliances', N'Blender', 99.00 UNION ALL
  SELECT N'Home & Kitchen', N'Cleaning', N'Vacuum', 199.00 UNION ALL
  SELECT N'Home & Kitchen', N'Appliances', N'Air Fryer', 139.00 UNION ALL
  SELECT N'Home & Kitchen', N'Appliances', N'Toaster', 49.00 UNION ALL
  SELECT N'Home & Kitchen', N'Appliances', N'Coffee Maker', 129.00 UNION ALL
  SELECT N'Home & Kitchen', N'Appliances', N'Microwave', 219.00 UNION ALL
  SELECT N'Apparel', N'Tops', N'T-Shirt', 20.00 UNION ALL
  SELECT N'Apparel', N'Bottoms', N'Jeans', 60.00 UNION ALL
  SELECT N'Apparel', N'Outerwear', N'Jacket', 120.00 UNION ALL
  SELECT N'Apparel', N'Footwear', N'Sneakers', 85.00 UNION ALL
  SELECT N'Apparel', N'Accessories', N'Socks', 10.00 UNION ALL
  SELECT N'Apparel', N'Accessories', N'Hat', 25.00 UNION ALL
  SELECT N'Sports & Outdoors', N'Fitness', N'Yoga Mat', 30.00 UNION ALL
  SELECT N'Sports & Outdoors', N'Strength', N'Dumbbells', 50.00 UNION ALL
  SELECT N'Sports & Outdoors', N'Racquet', N'Tennis Racket', 120.00 UNION ALL
  SELECT N'Sports & Outdoors', N'Team Sports', N'Basketball', 35.00 UNION ALL
  SELECT N'Sports & Outdoors', N'Cycling', N'Cycling Helmet', 75.00 UNION ALL
  SELECT N'Sports & Outdoors', N'Camping', N'Camping Tent', 150.00 UNION ALL
  SELECT N'Grocery', N'Produce', N'Organic Apples', 5.00 UNION ALL
  SELECT N'Grocery', N'Beverages', N'Almond Milk', 3.50 UNION ALL
  SELECT N'Grocery', N'Pantry', N'Coffee Beans', 12.50 UNION ALL
  SELECT N'Grocery', N'Pantry', N'Olive Oil', 9.99 UNION ALL
  SELECT N'Grocery', N'Pantry', N'Pasta', 2.50 UNION ALL
  SELECT N'Grocery', N'Pantry', N'Granola', 6.50
),
Brands AS (
  SELECT N'Electronics' AS Category, N'Contoso' AS Brand UNION ALL
  SELECT N'Electronics', N'Fabrikam' UNION ALL
  SELECT N'Electronics', N'AdventureTech' UNION ALL
  SELECT N'Electronics', N'Northwind Electronics' UNION ALL
  SELECT N'Home & Kitchen', N'KitchenPro' UNION ALL
  SELECT N'Home & Kitchen', N'HomeWorks' UNION ALL
  SELECT N'Home & Kitchen', N'AeroHome' UNION ALL
  SELECT N'Apparel', N'TailorCo' UNION ALL
  SELECT N'Apparel', N'ModernWear' UNION ALL
  SELECT N'Apparel', N'UrbanFabric' UNION ALL
  SELECT N'Sports & Outdoors', N'TrailRunner' UNION ALL
  SELECT N'Sports & Outdoors', N'FitGear' UNION ALL
  SELECT N'Sports & Outdoors', N'OutdoorX' UNION ALL
  SELECT N'Grocery', N'FreshFarm' UNION ALL
  SELECT N'Grocery', N'DailyDairy' UNION ALL
  SELECT N'Grocery', N'PantryPlus'
),
Products AS (
  SELECT TOP (80)
    i.Category,
    i.Subcategory,
    b.Brand,
    ProductName = b.Brand + N' ' + i.ItemName,
    BasePrice   = i.BasePrice,
    VariantFactor = (ABS(CHECKSUM(NEWID())) % 21 - 10) / 100.0 -- -0.10 .. +0.10
  FROM Items i
  JOIN Brands b ON b.Category = i.Category
  ORDER BY NEWID()
),
Numbered AS (
  SELECT
    p.Category,
    p.Subcategory,
    p.Brand,
    p.ProductName,
    p.BasePrice,
    p.VariantFactor,
    rn = ROW_NUMBER() OVER (ORDER BY p.ProductName)
  FROM Products p
)
INSERT INTO dbo.DimProduct (SKU, ProductName, Category, Subcategory, Brand, UnitPrice)
SELECT
  SKU = UPPER(LEFT(Category,2)) + N'-' + RIGHT('0000' + CAST(rn AS varchar(10)), 4),
  ProductName,
  Category,
  Subcategory,
  Brand,
  UnitPrice = ROUND(BasePrice * (1.0 + VariantFactor), 2)
FROM Numbered n
WHERE NOT EXISTS (
  SELECT 1 FROM dbo.DimProduct dp
  WHERE dp.SKU = UPPER(LEFT(n.Category,2)) + N'-' + RIGHT('0000' + CAST(n.rn AS varchar(10)), 4)
);

-- Customers: generate ~400 realistic rows from first x last names, with segments and random region
;WITH Firsts AS (
  SELECT * FROM (VALUES
    (N'James'),(N'Mary'),(N'Robert'),(N'Patricia'),(N'John'),(N'Jennifer'),(N'Michael'),(N'Linda'),(N'William'),(N'Elizabeth'),
    (N'David'),(N'Barbara'),(N'Richard'),(N'Susan'),(N'Joseph'),(N'Jessica'),(N'Thomas'),(N'Sarah'),(N'Charles'),(N'Karen'),
    (N'Christopher'),(N'Nancy'),(N'Daniel'),(N'Lisa'),(N'Matthew'),(N'Margaret'),(N'Anthony'),(N'Sandra'),(N'Donald'),(N'Ashley')
  ) AS f(FirstName)
), Lasts AS (
  SELECT * FROM (VALUES
    (N'Smith'),(N'Johnson'),(N'Williams'),(N'Brown'),(N'Jones'),(N'Garcia'),(N'Miller'),(N'Davis'),(N'Rodriguez'),(N'Martinez'),
    (N'Hernandez'),(N'Lopez'),(N'Gonzalez'),(N'Wilson'),(N'Anderson'),(N'Thomas'),(N'Taylor'),(N'Moore'),(N'Jackson'),(N'Martin'),
    (N'Lee'),(N'Perez'),(N'Thompson'),(N'White'),(N'Harris'),(N'Sanchez'),(N'Clark'),(N'Ramirez'),(N'Lewis'),(N'Robinson')
  ) AS l(LastName)
), Segments AS (
  SELECT * FROM (VALUES (N'Consumer'),(N'Corporate'),(N'Small Business'),(N'Enterprise')) AS s(Segment)
), Candidates AS (
  SELECT TOP (500)
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,
    f.FirstName, l.LastName,
    s.Segment
  FROM Firsts f
  CROSS JOIN Lasts l
  CROSS JOIN Segments s
  ORDER BY NEWID()
)
INSERT INTO dbo.DimCustomer (CustomerID, FirstName, LastName, Email, Phone, Segment, RegionKey)
SELECT TOP (400)
  CustomerID = N'CUST-' + RIGHT('0000' + CAST(rn AS varchar(10)), 4),
  FirstName,
  LastName,
  Email = LOWER(REPLACE(FirstName,' ','') + N'.' + REPLACE(LastName,' ','') + N'@example.com'),
  Phone = N'555-' + RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS varchar(10)),3) + N'-' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS varchar(10)),4),
  Segment,
  RegionKey = (SELECT TOP 1 RegionKey FROM dbo.DimRegion ORDER BY NEWID())
FROM Candidates
WHERE NOT EXISTS (
  SELECT 1 FROM dbo.DimCustomer dc
  WHERE dc.CustomerID = N'CUST-' + RIGHT('0000' + CAST(Candidates.rn AS varchar(10)), 4)
)
ORDER BY rn;

-- Date dimension: 2023-01-01 to today (dynamic end for freshness)
DECLARE @Start date = '20230101', @End date = CAST(GETDATE() AS date), @d date;
IF @Start IS NULL OR @End IS NULL SET @Start = '20230101';
SET @d = @Start;
WHILE @d <= @End
BEGIN
  IF NOT EXISTS (SELECT 1 FROM dbo.DimDate WHERE DateKey = YEAR(@d)*10000 + MONTH(@d)*100 + DAY(@d))
  BEGIN
    INSERT INTO dbo.DimDate
      (DateKey, [Date], DayOfMonth, DayOfWeek, DayName, WeekOfYear, MonthNumber, MonthName, QuarterNumber, QuarterName, [Year], IsWeekend)
    VALUES
      (
        YEAR(@d)*10000 + MONTH(@d)*100 + DAY(@d),
        @d,
        DAY(@d),
        DATEPART(WEEKDAY, @d),
        DATENAME(WEEKDAY, @d),
        DATEPART(WEEK, @d),
        MONTH(@d),
        DATENAME(MONTH, @d),
        DATEPART(QUARTER, @d),
        N'Q' + CAST(DATEPART(QUARTER, @d) AS nvarchar(10)),
        YEAR(@d),
        CASE WHEN DATENAME(WEEKDAY, @d) IN (N'Saturday', N'Sunday') THEN 1 ELSE 0 END
      );
  END;
  SET @d = DATEADD(DAY, 1, @d);
END;
