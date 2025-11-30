USE Warehouse;
SET NOCOUNT ON;

-- Insert several thousand sales rows with realistic distributions
;WITH N AS (
  SELECT TOP (3000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
  FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.FactSales (DateKey, ProductKey, CustomerKey, RegionKey, ChannelKey, Quantity, UnitPrice, Discount)
SELECT
  DateKey = CASE WHEN RandPick.r < 70 THEN DRecent.DateKey ELSE DAny.DateKey END,
  P.ProductKey,
  C.CustomerKey,
  COALESCE(C.RegionKey, R.RegionKey) AS RegionKey,
  CH.ChannelKey,
  Quantity = 1 + ABS(CHECKSUM(NEWID())) % 5,
  UnitPrice = P.UnitPrice,
  Discount = CAST((ABS(CHECKSUM(NEWID())) % 5) * 0.05 AS decimal(5,2))
FROM N
CROSS APPLY (SELECT ABS(CHECKSUM(NEWID())) % 100 AS r) AS RandPick
CROSS APPLY (
  SELECT TOP 1 DateKey
  FROM dbo.DimDate
  WHERE [Date] >= DATEADD(DAY, -180, (SELECT MAX([Date]) FROM dbo.DimDate))
  ORDER BY NEWID()
) AS DRecent
CROSS APPLY (SELECT TOP 1 DateKey FROM dbo.DimDate ORDER BY NEWID()) AS DAny
CROSS APPLY (SELECT TOP 1 ProductKey, UnitPrice FROM dbo.DimProduct ORDER BY NEWID()) AS P
CROSS APPLY (SELECT TOP 1 CustomerKey, RegionKey FROM dbo.DimCustomer ORDER BY NEWID()) AS C
CROSS APPLY (SELECT TOP 1 RegionKey FROM dbo.DimRegion ORDER BY NEWID()) AS R
CROSS APPLY (SELECT TOP 1 ChannelKey FROM dbo.DimChannel ORDER BY NEWID()) AS CH;

-- Helpful: ensure at least 600 rows exist
IF (SELECT COUNT(*) FROM dbo.FactSales) < 600
BEGIN
  RAISERROR('FactSales generated fewer than expected rows', 10, 1);
END
