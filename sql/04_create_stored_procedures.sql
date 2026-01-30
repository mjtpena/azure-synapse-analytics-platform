-- =============================================
-- Create Stored Procedures
-- =============================================
-- This script creates stored procedures for ETL operations

USE [EnterpriseDW];
GO

-- Procedure to populate Date Dimension
CREATE OR ALTER PROCEDURE dim.PopulateDateDimension
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentDate DATE = @StartDate;

    WHILE @CurrentDate <= @EndDate
    BEGIN
        INSERT INTO dim.DimDate
        (
            DateKey,
            FullDate,
            DayOfMonth,
            DayName,
            DayOfWeek,
            DayOfYear,
            WeekOfYear,
            MonthName,
            MonthOfYear,
            Quarter,
            QuarterName,
            Year,
            IsWeekend,
            IsHoliday,
            FiscalYear,
            FiscalQuarter,
            FiscalMonth
        )
        SELECT
            CAST(FORMAT(@CurrentDate, 'yyyyMMdd') AS INT) AS DateKey,
            @CurrentDate AS FullDate,
            DAY(@CurrentDate) AS DayOfMonth,
            DATENAME(WEEKDAY, @CurrentDate) AS DayName,
            DATEPART(WEEKDAY, @CurrentDate) AS DayOfWeek,
            DATEPART(DAYOFYEAR, @CurrentDate) AS DayOfYear,
            DATEPART(WEEK, @CurrentDate) AS WeekOfYear,
            DATENAME(MONTH, @CurrentDate) AS MonthName,
            MONTH(@CurrentDate) AS MonthOfYear,
            DATEPART(QUARTER, @CurrentDate) AS Quarter,
            'Q' + CAST(DATEPART(QUARTER, @CurrentDate) AS VARCHAR(1)) AS QuarterName,
            YEAR(@CurrentDate) AS Year,
            CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
            0 AS IsHoliday, -- Can be updated separately with holiday logic
            CASE
                WHEN MONTH(@CurrentDate) >= 7 THEN YEAR(@CurrentDate) + 1
                ELSE YEAR(@CurrentDate)
            END AS FiscalYear,
            CASE
                WHEN MONTH(@CurrentDate) >= 7 THEN DATEPART(QUARTER, @CurrentDate) - 2
                ELSE DATEPART(QUARTER, @CurrentDate) + 2
            END AS FiscalQuarter,
            CASE
                WHEN MONTH(@CurrentDate) >= 7 THEN MONTH(@CurrentDate) - 6
                ELSE MONTH(@CurrentDate) + 6
            END AS FiscalMonth
        WHERE NOT EXISTS (
            SELECT 1 FROM dim.DimDate
            WHERE DateKey = CAST(FORMAT(@CurrentDate, 'yyyyMMdd') AS INT)
        );

        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END;

    PRINT 'Date dimension populated from ' + CAST(@StartDate AS VARCHAR(10)) + ' to ' + CAST(@EndDate AS VARCHAR(10));
END;
GO

-- Procedure to update Customer SCD Type 2
CREATE OR ALTER PROCEDURE dim.UpdateCustomerSCD
    @CustomerID VARCHAR(50),
    @CustomerName VARCHAR(200),
    @CustomerType VARCHAR(50),
    @Email VARCHAR(200),
    @Phone VARCHAR(50),
    @City VARCHAR(100),
    @State VARCHAR(50),
    @Country VARCHAR(100),
    @Region VARCHAR(100),
    @CustomerSegment VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @EndDate DATE = DATEADD(DAY, -1, @CurrentDate);

    -- Check if customer exists and if any attributes changed
    IF EXISTS (
        SELECT 1 FROM dim.DimCustomer
        WHERE CustomerID = @CustomerID AND IsCurrent = 1
        AND (
            CustomerName <> @CustomerName OR
            CustomerType <> @CustomerType OR
            ISNULL(Email, '') <> ISNULL(@Email, '') OR
            ISNULL(Phone, '') <> ISNULL(@Phone, '') OR
            ISNULL(City, '') <> ISNULL(@City, '') OR
            ISNULL(State, '') <> ISNULL(@State, '') OR
            ISNULL(Country, '') <> ISNULL(@Country, '') OR
            ISNULL(Region, '') <> ISNULL(@Region, '') OR
            ISNULL(CustomerSegment, '') <> ISNULL(@CustomerSegment, '')
        )
    )
    BEGIN
        -- Expire the current record
        UPDATE dim.DimCustomer
        SET EndDate = @EndDate,
            IsCurrent = 0,
            ModifiedDate = GETDATE()
        WHERE CustomerID = @CustomerID AND IsCurrent = 1;

        -- Insert new record
        INSERT INTO dim.DimCustomer
        (CustomerID, CustomerName, CustomerType, Email, Phone, City, State, Country, Region, CustomerSegment, EffectiveDate, EndDate, IsCurrent)
        VALUES
        (@CustomerID, @CustomerName, @CustomerType, @Email, @Phone, @City, @State, @Country, @Region, @CustomerSegment, @CurrentDate, NULL, 1);

        PRINT 'Customer SCD updated for CustomerID: ' + @CustomerID;
    END
    ELSE IF NOT EXISTS (SELECT 1 FROM dim.DimCustomer WHERE CustomerID = @CustomerID)
    BEGIN
        -- Insert new customer
        INSERT INTO dim.DimCustomer
        (CustomerID, CustomerName, CustomerType, Email, Phone, City, State, Country, Region, CustomerSegment, EffectiveDate, EndDate, IsCurrent)
        VALUES
        (@CustomerID, @CustomerName, @CustomerType, @Email, @Phone, @City, @State, @Country, @Region, @CustomerSegment, @CurrentDate, NULL, 1);

        PRINT 'New customer inserted: ' + @CustomerID;
    END;
END;
GO

-- Procedure to calculate customer RFM scores
CREATE OR ALTER PROCEDURE fact.CalculateCustomerRFM
AS
BEGIN
    SET NOCOUNT ON;

    -- Update customer activity with RFM scores
    UPDATE ca
    SET
        RecencyScore = NTILE(5) OVER (ORDER BY DaysSinceLastPurchase DESC),
        FrequencyScore = NTILE(5) OVER (ORDER BY TotalOrders),
        MonetaryScore = NTILE(5) OVER (ORDER BY TotalSalesAmount),
        RFMScore = CAST(NTILE(5) OVER (ORDER BY DaysSinceLastPurchase DESC) AS VARCHAR(1)) +
                   CAST(NTILE(5) OVER (ORDER BY TotalOrders) AS VARCHAR(1)) +
                   CAST(NTILE(5) OVER (ORDER BY TotalSalesAmount) AS VARCHAR(1)),
        ModifiedDate = GETDATE()
    FROM fact.FactCustomerActivity ca;

    PRINT 'Customer RFM scores calculated successfully';
END;
GO

-- Procedure to aggregate sales data
CREATE OR ALTER PROCEDURE fact.AggregateSalesData
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Update customer activity based on sales in date range
    MERGE fact.FactCustomerActivity AS target
    USING (
        SELECT
            fs.CustomerKey,
            CAST(FORMAT(GETDATE(), 'yyyyMMdd') AS INT) AS ActivityDateKey,
            MIN(fs.DateKey) AS FirstPurchaseDateKey,
            MAX(fs.DateKey) AS LastPurchaseDateKey,
            COUNT(DISTINCT fs.OrderID) AS TotalOrders,
            SUM(fs.Quantity) AS TotalQuantity,
            SUM(fs.SalesAmount) AS TotalSalesAmount,
            SUM(fs.DiscountAmount) AS TotalDiscountAmount,
            AVG(fs.SalesAmount) AS AverageOrderValue,
            SUM(fs.NetProfitAmount) AS LifetimeValue,
            DATEDIFF(DAY, MAX(fs.OrderDate), GETDATE()) AS DaysSinceLastPurchase,
            DATEDIFF(DAY, MIN(fs.OrderDate), GETDATE()) AS CustomerLifetimeDays
        FROM fact.FactSales fs
        WHERE fs.OrderDate BETWEEN @StartDate AND @EndDate
        GROUP BY fs.CustomerKey
    ) AS source
    ON target.CustomerKey = source.CustomerKey
    WHEN MATCHED THEN
        UPDATE SET
            target.FirstPurchaseDateKey = source.FirstPurchaseDateKey,
            target.LastPurchaseDateKey = source.LastPurchaseDateKey,
            target.TotalOrders = source.TotalOrders,
            target.TotalQuantity = source.TotalQuantity,
            target.TotalSalesAmount = source.TotalSalesAmount,
            target.TotalDiscountAmount = source.TotalDiscountAmount,
            target.AverageOrderValue = source.AverageOrderValue,
            target.LifetimeValue = source.LifetimeValue,
            target.DaysSinceLastPurchase = source.DaysSinceLastPurchase,
            target.CustomerLifetimeDays = source.CustomerLifetimeDays,
            target.ModifiedDate = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (CustomerKey, ActivityDateKey, FirstPurchaseDateKey, LastPurchaseDateKey,
                TotalOrders, TotalQuantity, TotalSalesAmount, TotalDiscountAmount,
                AverageOrderValue, LifetimeValue, DaysSinceLastPurchase, CustomerLifetimeDays)
        VALUES (source.CustomerKey, source.ActivityDateKey, source.FirstPurchaseDateKey,
                source.LastPurchaseDateKey, source.TotalOrders, source.TotalQuantity,
                source.TotalSalesAmount, source.TotalDiscountAmount, source.AverageOrderValue,
                source.LifetimeValue, source.DaysSinceLastPurchase, source.CustomerLifetimeDays);

    PRINT 'Sales data aggregated for date range: ' + CAST(@StartDate AS VARCHAR(10)) + ' to ' + CAST(@EndDate AS VARCHAR(10));
END;
GO

-- Procedure to refresh materialized views (statistics)
CREATE OR ALTER PROCEDURE etl.RefreshStatistics
AS
BEGIN
    SET NOCOUNT ON;

    -- Update statistics on fact tables
    UPDATE STATISTICS fact.FactSales;
    UPDATE STATISTICS fact.FactInventory;
    UPDATE STATISTICS fact.FactCustomerActivity;
    UPDATE STATISTICS fact.FactWebAnalytics;

    -- Update statistics on dimension tables
    UPDATE STATISTICS dim.DimCustomer;
    UPDATE STATISTICS dim.DimProduct;
    UPDATE STATISTICS dim.DimStore;
    UPDATE STATISTICS dim.DimEmployee;
    UPDATE STATISTICS dim.DimPromotion;
    UPDATE STATISTICS dim.DimDate;

    PRINT 'Statistics refreshed successfully';
END;
GO

PRINT 'All stored procedures created successfully';
GO
