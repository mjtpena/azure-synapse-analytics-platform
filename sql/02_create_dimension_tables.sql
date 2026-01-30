-- =============================================
-- Create Dimension Tables
-- =============================================
-- This script creates Type 2 Slowly Changing Dimension tables

USE [EnterpriseDW];
GO

-- Date Dimension
IF OBJECT_ID('dim.DimDate', 'U') IS NOT NULL
    DROP TABLE dim.DimDate;
GO

CREATE TABLE dim.DimDate
(
    DateKey INT NOT NULL,
    FullDate DATE NOT NULL,
    DayOfMonth INT NOT NULL,
    DayName VARCHAR(10) NOT NULL,
    DayOfWeek INT NOT NULL,
    DayOfYear INT NOT NULL,
    WeekOfYear INT NOT NULL,
    MonthName VARCHAR(10) NOT NULL,
    MonthOfYear INT NOT NULL,
    Quarter INT NOT NULL,
    QuarterName VARCHAR(10) NOT NULL,
    Year INT NOT NULL,
    IsWeekend BIT NOT NULL,
    IsHoliday BIT NOT NULL,
    FiscalYear INT NOT NULL,
    FiscalQuarter INT NOT NULL,
    FiscalMonth INT NOT NULL
)
WITH
(
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);
GO

-- Customer Dimension (SCD Type 2)
IF OBJECT_ID('dim.DimCustomer', 'U') IS NOT NULL
    DROP TABLE dim.DimCustomer;
GO

CREATE TABLE dim.DimCustomer
(
    CustomerKey INT IDENTITY(1,1) NOT NULL,
    CustomerID VARCHAR(50) NOT NULL,
    CustomerName VARCHAR(200) NOT NULL,
    CustomerType VARCHAR(50) NOT NULL,
    Email VARCHAR(200),
    Phone VARCHAR(50),
    AddressLine1 VARCHAR(200),
    AddressLine2 VARCHAR(200),
    City VARCHAR(100),
    State VARCHAR(50),
    PostalCode VARCHAR(20),
    Country VARCHAR(100),
    Region VARCHAR(100),
    CustomerSegment VARCHAR(50),
    CreditLimit DECIMAL(18,2),
    AccountManager VARCHAR(200),
    -- SCD Type 2 columns
    EffectiveDate DATE NOT NULL,
    EndDate DATE,
    IsCurrent BIT NOT NULL,
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

-- Product Dimension (SCD Type 2)
IF OBJECT_ID('dim.DimProduct', 'U') IS NOT NULL
    DROP TABLE dim.DimProduct;
GO

CREATE TABLE dim.DimProduct
(
    ProductKey INT IDENTITY(1,1) NOT NULL,
    ProductID VARCHAR(50) NOT NULL,
    ProductName VARCHAR(200) NOT NULL,
    ProductDescription VARCHAR(1000),
    Category VARCHAR(100) NOT NULL,
    SubCategory VARCHAR(100),
    Brand VARCHAR(100),
    Manufacturer VARCHAR(200),
    SKU VARCHAR(100),
    UnitPrice DECIMAL(18,2),
    StandardCost DECIMAL(18,2),
    ListPrice DECIMAL(18,2),
    UnitOfMeasure VARCHAR(20),
    Weight DECIMAL(10,2),
    WeightUnit VARCHAR(10),
    Size VARCHAR(50),
    Color VARCHAR(50),
    ProductLine VARCHAR(50),
    -- SCD Type 2 columns
    EffectiveDate DATE NOT NULL,
    EndDate DATE,
    IsCurrent BIT NOT NULL,
    -- Audit columns
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
)
WITH
(
    DISTRIBUTION = HASH(ProductKey),
    CLUSTERED COLUMNSTORE INDEX
);
GO

-- Store/Location Dimension (SCD Type 2)
IF OBJECT_ID('dim.DimStore', 'U') IS NOT NULL
    DROP TABLE dim.DimStore;
GO

CREATE TABLE dim.DimStore
(
    StoreKey INT IDENTITY(1,1) NOT NULL,
    StoreID VARCHAR(50) NOT NULL,
    StoreName VARCHAR(200) NOT NULL,
    StoreType VARCHAR(50),
    AddressLine1 VARCHAR(200),
    AddressLine2 VARCHAR(200),
    City VARCHAR(100),
    State VARCHAR(50),
    PostalCode VARCHAR(20),
    Country VARCHAR(100),
    Region VARCHAR(100),
    SquareFootage INT,
    OpenDate DATE,
    CloseDate DATE,
    StoreManager VARCHAR(200),
    PhoneNumber VARCHAR(50),
    -- SCD Type 2 columns
    EffectiveDate DATE NOT NULL,
    EndDate DATE,
    IsCurrent BIT NOT NULL,
    -- Audit columns
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
)
WITH
(
    DISTRIBUTION = HASH(StoreKey),
    CLUSTERED COLUMNSTORE INDEX
);
GO

-- Employee Dimension (SCD Type 2)
IF OBJECT_ID('dim.DimEmployee', 'U') IS NOT NULL
    DROP TABLE dim.DimEmployee;
GO

CREATE TABLE dim.DimEmployee
(
    EmployeeKey INT IDENTITY(1,1) NOT NULL,
    EmployeeID VARCHAR(50) NOT NULL,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    FullName VARCHAR(200) NOT NULL,
    Email VARCHAR(200),
    Phone VARCHAR(50),
    JobTitle VARCHAR(100),
    Department VARCHAR(100),
    Division VARCHAR(100),
    ManagerEmployeeID VARCHAR(50),
    HireDate DATE,
    TerminationDate DATE,
    EmployeeType VARCHAR(50),
    -- SCD Type 2 columns
    EffectiveDate DATE NOT NULL,
    EndDate DATE,
    IsCurrent BIT NOT NULL,
    -- Audit columns
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
)
WITH
(
    DISTRIBUTION = HASH(EmployeeKey),
    CLUSTERED COLUMNSTORE INDEX
);
GO

-- Promotion Dimension
IF OBJECT_ID('dim.DimPromotion', 'U') IS NOT NULL
    DROP TABLE dim.DimPromotion;
GO

CREATE TABLE dim.DimPromotion
(
    PromotionKey INT IDENTITY(1,1) NOT NULL,
    PromotionID VARCHAR(50) NOT NULL,
    PromotionName VARCHAR(200) NOT NULL,
    PromotionDescription VARCHAR(1000),
    PromotionType VARCHAR(50),
    DiscountPercentage DECIMAL(5,2),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    MinQuantity INT,
    MaxQuantity INT,
    IsActive BIT NOT NULL,
    -- Audit columns
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
)
WITH
(
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);
GO

PRINT 'All dimension tables created successfully';
GO
