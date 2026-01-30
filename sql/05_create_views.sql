-- =============================================
-- Create Views
-- =============================================
-- This script creates reporting views and aggregated views

USE [EnterpriseDW];
GO

-- Sales Summary View
CREATE OR ALTER VIEW views.vw_SalesSummary
AS
SELECT
    dd.FullDate AS SalesDate,
    dd.Year,
    dd.Quarter,
    dd.MonthName,
    dd.WeekOfYear,
    dc.CustomerName,
    dc.CustomerType,
    dc.CustomerSegment,
    dc.Region AS CustomerRegion,
    dp.ProductName,
    dp.Category AS ProductCategory,
    dp.SubCategory AS ProductSubCategory,
    dp.Brand,
    ds.StoreName,
    ds.StoreType,
    ds.Region AS StoreRegion,
    de.FullName AS EmployeeName,
    de.Department AS EmployeeDepartment,
    pr.PromotionName,
    pr.PromotionType,
    fs.OrderID,
    fs.Quantity,
    fs.UnitPrice,
    fs.SalesAmount,
    fs.DiscountAmount,
    fs.TaxAmount,
    fs.CostAmount,
    fs.GrossProfitAmount,
    fs.NetProfitAmount,
    CASE
        WHEN fs.SalesAmount > 0 THEN (fs.GrossProfitAmount / fs.SalesAmount) * 100
        ELSE 0
    END AS GrossProfitMarginPercent,
    CASE
        WHEN fs.SalesAmount > 0 THEN (fs.NetProfitAmount / fs.SalesAmount) * 100
        ELSE 0
    END AS NetProfitMarginPercent
FROM fact.FactSales fs
INNER JOIN dim.DimDate dd ON fs.DateKey = dd.DateKey
INNER JOIN dim.DimCustomer dc ON fs.CustomerKey = dc.CustomerKey
INNER JOIN dim.DimProduct dp ON fs.ProductKey = dp.ProductKey
INNER JOIN dim.DimStore ds ON fs.StoreKey = ds.StoreKey
INNER JOIN dim.DimEmployee de ON fs.EmployeeKey = de.EmployeeKey
LEFT JOIN dim.DimPromotion pr ON fs.PromotionKey = pr.PromotionKey;
GO

-- Customer Analytics View
CREATE OR ALTER VIEW views.vw_CustomerAnalytics
AS
SELECT
    dc.CustomerID,
    dc.CustomerName,
    dc.CustomerType,
    dc.CustomerSegment,
    dc.City,
    dc.State,
    dc.Country,
    dc.Region,
    fca.TotalOrders,
    fca.TotalQuantity,
    fca.TotalSalesAmount,
    fca.TotalDiscountAmount,
    fca.AverageOrderValue,
    fca.LifetimeValue,
    fca.DaysSinceLastPurchase,
    fca.CustomerLifetimeDays,
    fca.RecencyScore,
    fca.FrequencyScore,
    fca.MonetaryScore,
    fca.RFMScore,
    CASE
        WHEN fca.RFMScore IN ('555', '554', '544', '545', '454', '455', '445') THEN 'Champions'
        WHEN fca.RFMScore IN ('543', '444', '435', '355', '354', '345', '344', '335') THEN 'Loyal Customers'
        WHEN fca.RFMScore IN ('553', '551', '552', '541', '542', '533', '532', '531', '452', '451', '442', '441', '431', '453', '433', '432', '423', '353', '352', '351', '342', '341', '333', '323') THEN 'Potential Loyalists'
        WHEN fca.RFMScore IN ('512', '511', '422', '421', '412', '411', '311') THEN 'Recent Customers'
        WHEN fca.RFMScore IN ('525', '524', '523', '522', '521', '515', '514', '513', '425', '424', '413', '414', '415', '315', '314', '313') THEN 'Promising'
        WHEN fca.RFMScore IN ('535', '534', '443', '434', '343', '334', '325', '324') THEN 'Customers Needing Attention'
        WHEN fca.RFMScore IN ('331', '321', '312', '221', '213', '231', '241', '251') THEN 'About To Sleep'
        WHEN fca.RFMScore IN ('255', '254', '245', '244', '253', '252', '243', '242', '235', '234', '225', '224', '153', '152', '145', '143', '142', '135', '134, 133, 125, 124') THEN 'At Risk'
        WHEN fca.RFMScore IN ('155', '154', '144', '214', '215', '115, 114, 113') THEN 'Cannot Lose Them'
        WHEN fca.RFMScore IN ('332', '322', '233', '232, 223, 222, 132, 123, 122, 212, 211') THEN 'Hibernating'
        WHEN fca.RFMScore IN ('111', '112', '121', '131', '141', '151') THEN 'Lost'
        ELSE 'Unclassified'
    END AS CustomerSegmentRFM,
    ffd.FullDate AS FirstPurchaseDate,
    fld.FullDate AS LastPurchaseDate
FROM dim.DimCustomer dc
INNER JOIN fact.FactCustomerActivity fca ON dc.CustomerKey = fca.CustomerKey
LEFT JOIN dim.DimDate ffd ON fca.FirstPurchaseDateKey = ffd.DateKey
LEFT JOIN dim.DimDate fld ON fca.LastPurchaseDateKey = fld.DateKey
WHERE dc.IsCurrent = 1;
GO

-- Product Performance View
CREATE OR ALTER VIEW views.vw_ProductPerformance
AS
SELECT
    dp.ProductID,
    dp.ProductName,
    dp.Category,
    dp.SubCategory,
    dp.Brand,
    dd.Year,
    dd.Quarter,
    dd.MonthName,
    COUNT(DISTINCT fs.OrderID) AS TotalOrders,
    SUM(fs.Quantity) AS TotalQuantitySold,
    SUM(fs.SalesAmount) AS TotalSalesAmount,
    SUM(fs.CostAmount) AS TotalCostAmount,
    SUM(fs.GrossProfitAmount) AS TotalGrossProfit,
    SUM(fs.NetProfitAmount) AS TotalNetProfit,
    AVG(fs.UnitPrice) AS AverageUnitPrice,
    CASE
        WHEN SUM(fs.SalesAmount) > 0 THEN (SUM(fs.GrossProfitAmount) / SUM(fs.SalesAmount)) * 100
        ELSE 0
    END AS GrossProfitMarginPercent,
    RANK() OVER (PARTITION BY dd.Year, dd.Quarter ORDER BY SUM(fs.SalesAmount) DESC) AS SalesRank
FROM fact.FactSales fs
INNER JOIN dim.DimProduct dp ON fs.ProductKey = dp.ProductKey
INNER JOIN dim.DimDate dd ON fs.DateKey = dd.DateKey
WHERE dp.IsCurrent = 1
GROUP BY
    dp.ProductID,
    dp.ProductName,
    dp.Category,
    dp.SubCategory,
    dp.Brand,
    dd.Year,
    dd.Quarter,
    dd.MonthName;
GO

-- Store Performance View
CREATE OR ALTER VIEW views.vw_StorePerformance
AS
SELECT
    ds.StoreID,
    ds.StoreName,
    ds.StoreType,
    ds.City,
    ds.State,
    ds.Region,
    dd.Year,
    dd.Quarter,
    dd.MonthName,
    COUNT(DISTINCT fs.OrderID) AS TotalOrders,
    COUNT(DISTINCT fs.CustomerKey) AS UniqueCustomers,
    SUM(fs.Quantity) AS TotalQuantitySold,
    SUM(fs.SalesAmount) AS TotalSalesAmount,
    SUM(fs.GrossProfitAmount) AS TotalGrossProfit,
    SUM(fs.NetProfitAmount) AS TotalNetProfit,
    AVG(fs.SalesAmount) AS AverageOrderValue,
    CASE
        WHEN SUM(fs.SalesAmount) > 0 THEN (SUM(fs.GrossProfitAmount) / SUM(fs.SalesAmount)) * 100
        ELSE 0
    END AS GrossProfitMarginPercent
FROM fact.FactSales fs
INNER JOIN dim.DimStore ds ON fs.StoreKey = ds.StoreKey
INNER JOIN dim.DimDate dd ON fs.DateKey = dd.DateKey
WHERE ds.IsCurrent = 1
GROUP BY
    ds.StoreID,
    ds.StoreName,
    ds.StoreType,
    ds.City,
    ds.State,
    ds.Region,
    dd.Year,
    dd.Quarter,
    dd.MonthName;
GO

-- Inventory Analysis View
CREATE OR ALTER VIEW views.vw_InventoryAnalysis
AS
SELECT
    dp.ProductID,
    dp.ProductName,
    dp.Category,
    dp.SubCategory,
    ds.StoreName,
    ds.Region,
    dd.FullDate AS SnapshotDate,
    fi.QuantityOnHand,
    fi.QuantityOnOrder,
    fi.QuantityReserved,
    fi.QuantityAvailable,
    fi.UnitCost,
    fi.InventoryValue,
    fi.ReorderPoint,
    fi.SafetyStockLevel,
    fi.DaysOfSupply,
    CASE
        WHEN fi.QuantityOnHand <= fi.ReorderPoint THEN 'Reorder Required'
        WHEN fi.QuantityOnHand <= fi.SafetyStockLevel THEN 'Below Safety Stock'
        WHEN fi.DaysOfSupply < 7 THEN 'Low Stock'
        WHEN fi.DaysOfSupply > 90 THEN 'Overstock'
        ELSE 'Normal'
    END AS StockStatus
FROM fact.FactInventory fi
INNER JOIN dim.DimProduct dp ON fi.ProductKey = dp.ProductKey
INNER JOIN dim.DimStore ds ON fi.StoreKey = ds.StoreKey
INNER JOIN dim.DimDate dd ON fi.DateKey = dd.DateKey
WHERE dp.IsCurrent = 1 AND ds.IsCurrent = 1;
GO

-- Web Analytics Summary View
CREATE OR ALTER VIEW views.vw_WebAnalyticsSummary
AS
SELECT
    dd.FullDate AS EventDate,
    dd.Year,
    dd.MonthName,
    fw.PageCategory,
    fw.DeviceType,
    fw.Browser,
    fw.ReferralSource,
    COUNT(DISTINCT fw.SessionID) AS TotalSessions,
    SUM(fw.PageViews) AS TotalPageViews,
    AVG(fw.TimeOnPage) AS AverageTimeOnPage,
    SUM(CAST(fw.BounceFlag AS INT)) AS TotalBounces,
    SUM(CAST(fw.ConversionFlag AS INT)) AS TotalConversions,
    SUM(CAST(fw.AddToCartFlag AS INT)) AS TotalAddToCarts,
    SUM(CAST(fw.CheckoutFlag AS INT)) AS TotalCheckouts,
    CASE
        WHEN COUNT(DISTINCT fw.SessionID) > 0
        THEN (CAST(SUM(CAST(fw.BounceFlag AS INT)) AS FLOAT) / COUNT(DISTINCT fw.SessionID)) * 100
        ELSE 0
    END AS BounceRate,
    CASE
        WHEN COUNT(DISTINCT fw.SessionID) > 0
        THEN (CAST(SUM(CAST(fw.ConversionFlag AS INT)) AS FLOAT) / COUNT(DISTINCT fw.SessionID)) * 100
        ELSE 0
    END AS ConversionRate
FROM fact.FactWebAnalytics fw
INNER JOIN dim.DimDate dd ON fw.DateKey = dd.DateKey
GROUP BY
    dd.FullDate,
    dd.Year,
    dd.MonthName,
    fw.PageCategory,
    fw.DeviceType,
    fw.Browser,
    fw.ReferralSource;
GO

PRINT 'All views created successfully';
GO
