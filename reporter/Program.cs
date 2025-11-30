using System;
using System.Data;
using Microsoft.Data.SqlClient;
using System.Threading.Tasks;

class Program
{
    static async Task<int> Main()
    {
        var pwd = Environment.GetEnvironmentVariable("SA_PASSWORD");
        if (string.IsNullOrWhiteSpace(pwd))
        {
            Console.Error.WriteLine("SA_PASSWORD env var is missing");
            return 1;
        }
        var masterCs = new SqlConnectionStringBuilder
        {
            DataSource = "db,1433",
            UserID = "sa",
            Password = pwd,
            Encrypt = true,
            TrustServerCertificate = true,
            InitialCatalog = "master",
            ConnectTimeout = 30
        }.ConnectionString;
        var dwCs = new SqlConnectionStringBuilder
        {
            DataSource = "db,1433",
            UserID = "sa",
            Password = pwd,
            Encrypt = true,
            TrustServerCertificate = true,
            InitialCatalog = "Warehouse",
            ConnectTimeout = 30
        }.ConnectionString;

        try
        {
            using var master = new SqlConnection(masterCs);
            await master.OpenAsync();
            Console.WriteLine("Connected to server. Version: " + master.ServerVersion);

            // Ensure Warehouse exists; if not, run seed scripts from /init
            if (!await DatabaseExists(master, "Warehouse"))
            {
                Console.WriteLine("Warehouse DB not found. Running seed scripts...");
                await RunSqlFile(master, "/init/01_create_schema.sql");
                await RunSqlFile(master, "/init/02_seed_dimensions.sql");
                await RunSqlFile(master, "/init/03_seed_facts.sql");
                Console.WriteLine("Seeding complete.");
            }

            using var conn = new SqlConnection(dwCs);
            await conn.OpenAsync();

            // Verify counts
            Console.WriteLine("\nRow counts:");
            await QueryAndPrint(conn, @"
SELECT 'DimDate' AS TableName, COUNT(*) AS Rows FROM dbo.DimDate
UNION ALL SELECT 'DimRegion', COUNT(*) FROM dbo.DimRegion
UNION ALL SELECT 'DimCustomer', COUNT(*) FROM dbo.DimCustomer
UNION ALL SELECT 'DimProduct', COUNT(*) FROM dbo.DimProduct
UNION ALL SELECT 'DimChannel', COUNT(*) FROM dbo.DimChannel
UNION ALL SELECT 'FactSales', COUNT(*) FROM dbo.FactSales;");

            // Revenue by category (last 90 days)
Console.WriteLine("\nRows in last 90 days:");
            await QueryAndPrint(conn, @"DECLARE @anchor date = (SELECT MAX([Date]) FROM dbo.DimDate);
SELECT COUNT(*) AS Rows90
FROM dbo.FactSales f
JOIN dbo.DimDate d ON d.DateKey = f.DateKey
WHERE d.[Date] >= DATEADD(DAY, -90, @anchor);");

            Console.WriteLine("\nRevenue by category (last 90 days):");
            await QueryAndPrint(conn, @"DECLARE @anchor date = (SELECT MAX([Date]) FROM dbo.DimDate);
SELECT p.Category, SUM(f.SalesAmount) AS Revenue
FROM dbo.FactSales f
JOIN dbo.DimProduct p ON p.ProductKey = f.ProductKey
JOIN dbo.DimDate d ON d.DateKey = f.DateKey
WHERE d.[Date] >= DATEADD(DAY, -90, @anchor)
GROUP BY p.Category
ORDER BY Revenue DESC;");

            // Top 10 customers
            Console.WriteLine("\nTop 10 customers by spend:");
            await QueryAndPrint(conn, @"SELECT TOP 10 c.CustomerID, c.FirstName, c.LastName, c.Segment, SUM(f.SalesAmount) AS Spend
FROM dbo.FactSales f
JOIN dbo.DimCustomer c ON c.CustomerKey = f.CustomerKey
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Segment
ORDER BY Spend DESC;");

            // Channel mix by region group
            Console.WriteLine("\nChannel mix by region group:");
            await QueryAndPrint(conn, @"SELECT r.RegionGroup, ch.ChannelName, SUM(f.SalesAmount) AS Revenue
FROM dbo.FactSales f
JOIN dbo.DimRegion r  ON r.RegionKey  = f.RegionKey
JOIN dbo.DimChannel ch ON ch.ChannelKey = f.ChannelKey
GROUP BY r.RegionGroup, ch.ChannelName
ORDER BY r.RegionGroup, Revenue DESC;");

            // Last 7 days revenue trend
Console.WriteLine("\nAll-time revenue by category:");
            await QueryAndPrint(conn, @"SELECT p.Category, SUM(f.SalesAmount) AS Revenue
FROM dbo.FactSales f
JOIN dbo.DimProduct p ON p.ProductKey = f.ProductKey
GROUP BY p.Category
ORDER BY Revenue DESC;");

            Console.WriteLine("\nLast 7 days revenue trend:");
            await QueryAndPrint(conn, @"DECLARE @anchor date = (SELECT MAX([Date]) FROM dbo.DimDate);
SELECT d.[Date], SUM(f.SalesAmount) AS Revenue
FROM dbo.FactSales f
JOIN dbo.DimDate d ON d.DateKey = f.DateKey
WHERE d.[Date] >= DATEADD(DAY, -7, @anchor)
GROUP BY d.[Date]
ORDER BY d.[Date];");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.ToString());
            return 2;
        }
        return 0;
    }

    static async Task QueryAndPrint(SqlConnection conn, string sql)
    {
        using var cmd = new SqlCommand(sql, conn);
        using var rdr = await cmd.ExecuteReaderAsync();
        do
        {
            var schema = rdr.GetColumnSchema();
            for (int i = 0; i < schema.Count; i++)
                Console.Write(i == 0 ? schema[i].ColumnName : " | " + schema[i].ColumnName);
            Console.WriteLine();
            while (await rdr.ReadAsync())
            {
                for (int i = 0; i < rdr.FieldCount; i++)
                {
                    var val = rdr.IsDBNull(i) ? "NULL" : Convert.ToString(rdr.GetValue(i));
                    Console.Write(i == 0 ? val : " | " + val);
                }
                Console.WriteLine();
            }
        } while (await rdr.NextResultAsync());
    }

    static async Task<bool> DatabaseExists(SqlConnection conn, string dbName)
    {
        using var cmd = new SqlCommand("SELECT CASE WHEN DB_ID(@n) IS NULL THEN 0 ELSE 1 END", conn);
        cmd.Parameters.AddWithValue("@n", dbName);
        var result = (int)await cmd.ExecuteScalarAsync();
        return result == 1;
    }

    static async Task RunSqlFile(SqlConnection conn, string path)
    {
        if (!System.IO.File.Exists(path))
        {
            throw new InvalidOperationException($"SQL file not found: {path}");
        }
        var lines = await System.IO.File.ReadAllLinesAsync(path);
        var sb = new System.Text.StringBuilder();
        foreach (var raw in lines)
        {
            var line = raw;
            if (line.Trim().Equals("GO", StringComparison.OrdinalIgnoreCase))
            {
                await ExecuteBatch(conn, sb.ToString());
                sb.Clear();
            }
            else
            {
                sb.AppendLine(line);
            }
        }
        if (sb.Length > 0)
        {
            await ExecuteBatch(conn, sb.ToString());
        }
    }

    static async Task ExecuteBatch(SqlConnection conn, string sql)
    {
        using var cmd = new SqlCommand(sql, conn);
        cmd.CommandTimeout = 120;
        await cmd.ExecuteNonQueryAsync();
    }
}
