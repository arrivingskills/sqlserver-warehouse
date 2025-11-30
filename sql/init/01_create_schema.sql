SET NOCOUNT ON;
IF DB_ID('Warehouse') IS NULL CREATE DATABASE Warehouse;
GO
USE Warehouse;
GO

-- Drop existing tables to allow re-runs
IF OBJECT_ID('dbo.FactSales','U') IS NOT NULL DROP TABLE dbo.FactSales;
IF OBJECT_ID('dbo.DimChannel','U') IS NOT NULL DROP TABLE dbo.DimChannel;
IF OBJECT_ID('dbo.DimProduct','U') IS NOT NULL DROP TABLE dbo.DimProduct;
IF OBJECT_ID('dbo.DimCustomer','U') IS NOT NULL DROP TABLE dbo.DimCustomer;
IF OBJECT_ID('dbo.DimRegion','U') IS NOT NULL DROP TABLE dbo.DimRegion;
IF OBJECT_ID('dbo.DimDate','U')   IS NOT NULL DROP TABLE dbo.DimDate;
GO

CREATE TABLE dbo.DimDate (
  DateKey       int        NOT NULL PRIMARY KEY,  -- yyyymmdd
  [Date]        date       NOT NULL,
  DayOfMonth    tinyint    NOT NULL,
  DayOfWeek     tinyint    NOT NULL,
  DayName       nvarchar(10) NOT NULL,
  WeekOfYear    tinyint    NOT NULL,
  MonthNumber   tinyint    NOT NULL,
  MonthName     nvarchar(10) NOT NULL,
  QuarterNumber tinyint    NOT NULL,
  QuarterName   nvarchar(6)  NOT NULL,
  [Year]        smallint   NOT NULL,
  IsWeekend     bit        NOT NULL
);

CREATE TABLE dbo.DimRegion (
  RegionKey     int IDENTITY(1,1) PRIMARY KEY,
  Country       nvarchar(60) NOT NULL,
  StateProvince nvarchar(60) NOT NULL,
  City          nvarchar(60) NOT NULL,
  RegionGroup   nvarchar(50) NULL,
  CONSTRAINT UX_DimRegion_Natural UNIQUE (Country, StateProvince, City)
);

CREATE TABLE dbo.DimCustomer (
  CustomerKey int IDENTITY(1,1) PRIMARY KEY,
  CustomerID  nvarchar(20) NOT NULL UNIQUE,
  FirstName   nvarchar(40) NOT NULL,
  LastName    nvarchar(40) NOT NULL,
  Email       nvarchar(100) NOT NULL,
  Phone       nvarchar(20) NULL,
  Segment     nvarchar(30) NOT NULL,
  RegionKey   int NULL REFERENCES dbo.DimRegion(RegionKey)
);

CREATE TABLE dbo.DimProduct (
  ProductKey   int IDENTITY(1,1) PRIMARY KEY,
  SKU          nvarchar(30) NOT NULL UNIQUE,
  ProductName  nvarchar(120) NOT NULL,
  Category     nvarchar(40) NOT NULL,
  Subcategory  nvarchar(40) NULL,
  Brand        nvarchar(40) NULL,
  UnitPrice    decimal(10,2) NOT NULL
);

CREATE TABLE dbo.DimChannel (
  ChannelKey  int IDENTITY(1,1) PRIMARY KEY,
  ChannelName nvarchar(30) NOT NULL UNIQUE
);

CREATE TABLE dbo.FactSales (
  FactSalesKey bigint IDENTITY(1,1) PRIMARY KEY,
  DateKey      int NOT NULL REFERENCES dbo.DimDate(DateKey),
  ProductKey   int NOT NULL REFERENCES dbo.DimProduct(ProductKey),
  CustomerKey  int NOT NULL REFERENCES dbo.DimCustomer(CustomerKey),
  RegionKey    int NOT NULL REFERENCES dbo.DimRegion(RegionKey),
  ChannelKey   int NOT NULL REFERENCES dbo.DimChannel(ChannelKey),
  Quantity     smallint NOT NULL CHECK (Quantity>0),
  UnitPrice    decimal(10,2) NOT NULL CHECK (UnitPrice>=0),
  Discount     decimal(5,2)  NOT NULL CONSTRAINT DF_FactSales_Discount DEFAULT (0) CHECK (Discount>=0 AND Discount<=0.8),
  SalesAmount  AS CAST(Quantity*UnitPrice*(1-Discount) AS decimal(12,2)) PERSISTED
);

-- Helpful nonclustered indexes on FKs
CREATE INDEX IX_FactSales_DateKey    ON dbo.FactSales(DateKey);
CREATE INDEX IX_FactSales_ProductKey ON dbo.FactSales(ProductKey);
CREATE INDEX IX_FactSales_CustomerKey ON dbo.FactSales(CustomerKey);
CREATE INDEX IX_FactSales_RegionKey  ON dbo.FactSales(RegionKey);
CREATE INDEX IX_FactSales_ChannelKey ON dbo.FactSales(ChannelKey);
