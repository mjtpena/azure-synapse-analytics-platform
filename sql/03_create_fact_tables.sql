-- =============================================
-- Create Fact Tables
-- =============================================
-- This script creates fact tables with appropriate partitioning and distribution

USE [EnterpriseDW];
GO

-- Sales Fact Table
IF OBJECT_ID('fact.FactSales', 'U') IS NOT NULL
    DROP TABLE fact.FactSales;
GO

CREATE TABLE fact.FactSales
(
    SalesKey BIGINT IDENTITY(1,1) NOT NULL,
    OrderID VARCHAR(50) NOT NULL,
    OrderLineNumber INT NOT NULL,
    DateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    StoreKey INT NOT NULL,
    EmployeeKey INT NOT NULL,
    PromotionKey INT,
    -- Measures
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    UnitCost DECIMAL(18,2) NOT NULL,
    DiscountAmount DECIMAL(18,2) DEFAULT 0,
    TaxAmount DECIMAL(18,2) DEFAULT 0,
    SalesAmount DECIMAL(18,2) NOT NULL,
    CostAmount DECIMAL(18,2) NOT NULL,
    GrossProfitAmount DECIMAL(18,2) NOT NULL,
    NetProfitAmount DECIMAL(18,2) NOT NULL,
    -- Degenerate dimensions
    OrderDate DATE NOT NULL,
    ShipDate DATE,
    PaymentMethod VARCHAR(50),
    ShippingMethod VARCHAR(50),
    -- Audit columns
    CreatedDate DATETIME2 DEFAULT GETDATE()
)
WITH
(
    DISTRIBUTION = HASH(CustomerKey),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (DateKey RANGE RIGHT FOR VALUES (
        20230101, 20230201, 20230301, 20230401, 20230501, 20230601,
        20230701, 20230801, 20230901, 20231001, 20231101, 20231201,
        20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
        20240701, 20240801, 20240901, 20241001, 20241101, 20241201,
        20250101, 20250201, 20250301, 20250401, 20250501, 20250601,
        20250701, 20250801, 20250901, 20251001, 20251101, 20251201
    ))
);
GO

-- Inventory Fact Table (Periodic Snapshot)
IF OBJECT_ID('fact.FactInventory', 'U') IS NOT NULL
    DROP TABLE fact.FactInventory;
GO

CREATE TABLE fact.FactInventory
(
    InventoryKey BIGINT IDENTITY(1,1) NOT NULL,
    DateKey INT NOT NULL,
    ProductKey INT NOT NULL,
    StoreKey INT NOT NULL,
    -- Measures
    QuantityOnHand INT NOT NULL,
    QuantityOnOrder INT NOT NULL,
    QuantityReserved INT NOT NULL,
    QuantityAvailable INT NOT NULL,
    UnitCost DECIMAL(18,2) NOT NULL,
    InventoryValue DECIMAL(18,2) NOT NULL,
    ReorderPoint INT,
    SafetyStockLevel INT,
    DaysOfSupply INT,
    -- Audit columns
    SnapshotDate DATE NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE()
)
WITH
(
    DISTRIBUTION = HASH(ProductKey),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (DateKey RANGE RIGHT FOR VALUES (
        20230101, 20230201, 20230301, 20230401, 20230501, 20230601,
        20230701, 20230801, 20230901, 20231001, 20231101, 20231201,
        20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
        20240701, 20240801, 20240901, 20241001, 20241101, 20241201,
        20250101, 20250201, 20250301, 20250401, 20250501, 20250601,
        20250701, 20250801, 20250901, 20251001, 20251101, 20251201
    ))
);
GO

-- Customer Activity Fact Table (Accumulating Snapshot)
IF OBJECT_ID('fact.FactCustomerActivity', 'U') IS NOT NULL
    DROP TABLE fact.FactCustomerActivity;
GO

CREATE TABLE fact.FactCustomerActivity
(
    ActivityKey BIGINT IDENTITY(1,1) NOT NULL,
    CustomerKey INT NOT NULL,
    ActivityDateKey INT NOT NULL,
    -- Milestone dates
    FirstPurchaseDateKey INT,
    LastPurchaseDateKey INT,
    -- Measures
    TotalOrders INT DEFAULT 0,
    TotalQuantity INT DEFAULT 0,
    TotalSalesAmount DECIMAL(18,2) DEFAULT 0,
    TotalDiscountAmount DECIMAL(18,2) DEFAULT 0,
    AverageOrderValue DECIMAL(18,2) DEFAULT 0,
    LifetimeValue DECIMAL(18,2) DEFAULT 0,
    DaysSinceLastPurchase INT,
    CustomerLifetimeDays INT,
    -- Segmentation
    RecencyScore INT,
    FrequencyScore INT,
    MonetaryScore INT,
    RFMScore VARCHAR(10),
    -- Audit columns
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
)
WITH
(
    DISTRIBUTION = HASH(CustomerKey),
    CLUSTERED COLUMNSTORE INDEX
);
GO

-- Web Analytics Fact Table (Transactional)
IF OBJECT_ID('fact.FactWebAnalytics', 'U') IS NOT NULL
    DROP TABLE fact.FactWebAnalytics;
GO

CREATE TABLE fact.FactWebAnalytics
(
    WebAnalyticsKey BIGINT IDENTITY(1,1) NOT NULL,
    DateKey INT NOT NULL,
    CustomerKey INT,
    ProductKey INT,
    -- Dimensions
    SessionID VARCHAR(100) NOT NULL,
    PageURL VARCHAR(500),
    PageCategory VARCHAR(100),
    DeviceType VARCHAR(50),
    Browser VARCHAR(50),
    OperatingSystem VARCHAR(50),
    ReferralSource VARCHAR(200),
    -- Measures
    PageViews INT DEFAULT 1,
    TimeOnPage INT, -- seconds
    BounceFlag BIT DEFAULT 0,
    ConversionFlag BIT DEFAULT 0,
    AddToCartFlag BIT DEFAULT 0,
    CheckoutFlag BIT DEFAULT 0,
    -- Degenerate dimensions
    EventTimestamp DATETIME2 NOT NULL,
    -- Audit columns
    CreatedDate DATETIME2 DEFAULT GETDATE()
)
WITH
(
    DISTRIBUTION = HASH(SessionID),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (DateKey RANGE RIGHT FOR VALUES (
        20230101, 20230201, 20230301, 20230401, 20230501, 20230601,
        20230701, 20230801, 20230901, 20231001, 20231101, 20231201,
        20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
        20240701, 20240801, 20240901, 20241001, 20241101, 20241201,
        20250101, 20250201, 20250301, 20250401, 20250501, 20250601,
        20250701, 20250801, 20250901, 20251001, 20251101, 20251201
    ))
);
GO

PRINT 'All fact tables created successfully';
GO
