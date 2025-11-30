# Containerized SQL Server Data Warehouse (Star Schema)

This example spins up Microsoft SQL Server in Docker and auto-seeds a small star schema for retail-like sales.

## Contents
- `docker-compose.yml` – SQL Server (`db`) and a one-shot seeding container (`seed`).
- `sql/init/*.sql` – schema creation and data seed scripts.
- `.env.example` – copy to `.env` and set `SA_PASSWORD`.

## Quick start
1. cd into this folder:
   ```
   cd sqlserver-warehouse
   ```
2. Create `.env` from the example and set a strong password:
   ```
   cp .env.example .env
   # edit .env and change SA_PASSWORD
   ```
3. Start the stack (the `seed` container exits when data is loaded):
   ```
   docker compose up -d
   docker compose logs -f seed
   ```
4. Connect with your SQL tool (Azure Data Studio, DBeaver, etc.):
   - Server: `localhost`
   - Port: `1433`
   - User: `sa`
   - Password: value of `SA_PASSWORD` in `.env`
   - Database: `Warehouse`

## What you get
- Dimensions: `DimDate`, `DimRegion`, `DimCustomer`, `DimProduct`, `DimChannel`
- Fact: `FactSales` with measures `Quantity`, `UnitPrice`, `Discount`, computed `SalesAmount`
- ~80 products, ~400 customers, ~30 cities/regions, ~1K dates, ~3,000 sales rows

## Sample queries
Total sales by category (last 90 days):
```sql
SELECT p.Category, SUM(f.SalesAmount) AS Revenue
FROM dbo.FactSales f
JOIN dbo.DimProduct p ON p.ProductKey = f.ProductKey
JOIN dbo.DimDate d ON d.DateKey = f.DateKey
WHERE d.[Date] >= DATEADD(DAY, -90, CAST(GETDATE() AS date))
GROUP BY p.Category
ORDER BY Revenue DESC;
```
Top 10 customers by spend:
```sql
SELECT TOP 10 c.CustomerID, c.FirstName, c.LastName, SUM(f.SalesAmount) AS Spend
FROM dbo.FactSales f
JOIN dbo.DimCustomer c ON c.CustomerKey = f.CustomerKey
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY Spend DESC;
```
Daily revenue trend for the last 30 days:
```sql
SELECT d.[Date], SUM(f.SalesAmount) AS Revenue
FROM dbo.FactSales f
JOIN dbo.DimDate d ON d.DateKey = f.DateKey
WHERE d.[Date] >= DATEADD(DAY, -30, CAST(GETDATE() AS date))
GROUP BY d.[Date]
ORDER BY d.[Date];
```

## Maintenance
- To rebuild data: `docker compose up -d --force-recreate --no-deps seed` or tear down volumes: `docker compose down -v` then `docker compose up -d`.
- Data persists in the `mssql-data` named volume.
