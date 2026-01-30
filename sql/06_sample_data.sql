-- =============================================
-- Sample Data Population
-- =============================================
-- This script populates sample data for testing

USE [EnterpriseDW];
GO

-- Populate Date Dimension (2023-2025)
EXEC dim.PopulateDateDimension '2023-01-01', '2025-12-31';
GO

-- Insert sample customers
INSERT INTO dim.DimCustomer (CustomerID, CustomerName, CustomerType, Email, Phone, City, State, Country, Region, CustomerSegment, EffectiveDate, IsCurrent)
VALUES
('CUST001', 'Acme Corporation', 'Enterprise', 'contact@acme.com', '555-0101', 'New York', 'NY', 'USA', 'Northeast', 'Premium', '2023-01-01', 1),
('CUST002', 'TechStart Inc', 'SMB', 'info@techstart.com', '555-0102', 'San Francisco', 'CA', 'USA', 'West', 'Standard', '2023-01-01', 1),
('CUST003', 'Global Retail Ltd', 'Enterprise', 'sales@globalretail.com', '555-0103', 'Chicago', 'IL', 'USA', 'Midwest', 'Premium', '2023-01-01', 1),
('CUST004', 'Small Business Co', 'SMB', 'owner@smallbiz.com', '555-0104', 'Austin', 'TX', 'USA', 'South', 'Standard', '2023-02-15', 1),
('CUST005', 'Enterprise Solutions', 'Enterprise', 'contact@entsol.com', '555-0105', 'Seattle', 'WA', 'USA', 'West', 'Premium', '2023-03-01', 1);
GO

-- Insert sample products
INSERT INTO dim.DimProduct (ProductID, ProductName, ProductDescription, Category, SubCategory, Brand, SKU, UnitPrice, StandardCost, ListPrice, EffectiveDate, IsCurrent)
VALUES
('PROD001', 'Enterprise Software License', 'Annual software license for enterprise', 'Software', 'Enterprise Solutions', 'TechBrand', 'SKU-SW-001', 9999.99, 4000.00, 12000.00, '2023-01-01', 1),
('PROD002', 'Cloud Storage 1TB', '1TB cloud storage subscription', 'Cloud Services', 'Storage', 'CloudBrand', 'SKU-CS-001', 99.99, 30.00, 120.00, '2023-01-01', 1),
('PROD003', 'Business Analytics Tool', 'Advanced analytics platform', 'Software', 'Analytics', 'DataBrand', 'SKU-SW-002', 499.99, 150.00, 600.00, '2023-01-01', 1),
('PROD004', 'API Management Platform', 'Enterprise API gateway', 'Cloud Services', 'Integration', 'TechBrand', 'SKU-CS-002', 299.99, 100.00, 350.00, '2023-01-01', 1),
('PROD005', 'Mobile App License', 'Mobile application license per user', 'Software', 'Mobile', 'AppBrand', 'SKU-SW-003', 49.99, 10.00, 60.00, '2023-01-01', 1);
GO

-- Insert sample stores
INSERT INTO dim.DimStore (StoreID, StoreName, StoreType, City, State, Country, Region, OpenDate, EffectiveDate, IsCurrent)
VALUES
('STORE001', 'Headquarters Store', 'Flagship', 'New York', 'NY', 'USA', 'Northeast', '2020-01-01', '2023-01-01', 1),
('STORE002', 'West Coast Branch', 'Regional', 'San Francisco', 'CA', 'USA', 'West', '2020-06-01', '2023-01-01', 1),
('STORE003', 'Midwest Hub', 'Regional', 'Chicago', 'IL', 'USA', 'Midwest', '2021-01-01', '2023-01-01', 1),
('STORE004', 'South Regional', 'Regional', 'Dallas', 'TX', 'USA', 'South', '2021-06-01', '2023-01-01', 1),
('STORE005', 'Online Store', 'Virtual', 'Seattle', 'WA', 'USA', 'West', '2019-01-01', '2023-01-01', 1);
GO

-- Insert sample employees
INSERT INTO dim.DimEmployee (EmployeeID, FirstName, LastName, FullName, Email, JobTitle, Department, HireDate, EmployeeType, EffectiveDate, IsCurrent)
VALUES
('EMP001', 'John', 'Smith', 'John Smith', 'jsmith@company.com', 'Sales Manager', 'Sales', '2020-01-15', 'Full-Time', '2023-01-01', 1),
('EMP002', 'Sarah', 'Johnson', 'Sarah Johnson', 'sjohnson@company.com', 'Senior Sales Rep', 'Sales', '2020-03-01', 'Full-Time', '2023-01-01', 1),
('EMP003', 'Michael', 'Brown', 'Michael Brown', 'mbrown@company.com', 'Sales Rep', 'Sales', '2021-01-10', 'Full-Time', '2023-01-01', 1),
('EMP004', 'Emily', 'Davis', 'Emily Davis', 'edavis@company.com', 'Sales Rep', 'Sales', '2021-06-15', 'Full-Time', '2023-01-01', 1),
('EMP005', 'Robert', 'Wilson', 'Robert Wilson', 'rwilson@company.com', 'Account Executive', 'Sales', '2022-01-05', 'Full-Time', '2023-01-01', 1);
GO

-- Insert sample promotions
INSERT INTO dim.DimPromotion (PromotionID, PromotionName, PromotionDescription, PromotionType, DiscountPercentage, StartDate, EndDate, IsActive)
VALUES
('PROMO001', 'New Year Sale', 'Start the year with savings', 'Percentage', 15.00, '2023-01-01', '2023-01-31', 0),
('PROMO002', 'Spring Special', 'Spring into savings', 'Percentage', 10.00, '2023-03-01', '2023-03-31', 0),
('PROMO003', 'Summer Clearance', 'Hot summer deals', 'Percentage', 20.00, '2023-06-01', '2023-06-30', 0),
('PROMO004', 'Fall Festival', 'Fall into great prices', 'Percentage', 12.00, '2023-09-01', '2023-09-30', 0),
('PROMO005', 'Holiday Bonanza', 'Holiday shopping special', 'Percentage', 25.00, '2023-11-15', '2023-12-31', 0);
GO

-- Insert sample sales data
DECLARE @Counter INT = 1;
DECLARE @MaxRecords INT = 100;

WHILE @Counter <= @MaxRecords
BEGIN
    INSERT INTO fact.FactSales
    (
        OrderID,
        OrderLineNumber,
        DateKey,
        CustomerKey,
        ProductKey,
        StoreKey,
        EmployeeKey,
        PromotionKey,
        Quantity,
        UnitPrice,
        UnitCost,
        DiscountAmount,
        TaxAmount,
        SalesAmount,
        CostAmount,
        GrossProfitAmount,
        NetProfitAmount,
        OrderDate,
        PaymentMethod,
        ShippingMethod
    )
    SELECT
        'ORD' + RIGHT('00000' + CAST(@Counter AS VARCHAR(5)), 5) AS OrderID,
        1 AS OrderLineNumber,
        CAST(FORMAT(DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 365, '2023-01-01'), 'yyyyMMdd') AS INT) AS DateKey,
        (ABS(CHECKSUM(NEWID())) % 5) + 1 AS CustomerKey,
        (ABS(CHECKSUM(NEWID())) % 5) + 1 AS ProductKey,
        (ABS(CHECKSUM(NEWID())) % 5) + 1 AS StoreKey,
        (ABS(CHECKSUM(NEWID())) % 5) + 1 AS EmployeeKey,
        CASE WHEN ABS(CHECKSUM(NEWID())) % 10 < 3 THEN (ABS(CHECKSUM(NEWID())) % 5) + 1 ELSE NULL END AS PromotionKey,
        (ABS(CHECKSUM(NEWID())) % 10) + 1 AS Quantity,
        CAST((ABS(CHECKSUM(NEWID())) % 1000) + 50 AS DECIMAL(18,2)) AS UnitPrice,
        CAST((ABS(CHECKSUM(NEWID())) % 500) + 20 AS DECIMAL(18,2)) AS UnitCost,
        CAST((ABS(CHECKSUM(NEWID())) % 50) AS DECIMAL(18,2)) AS DiscountAmount,
        0 AS TaxAmount,
        0 AS SalesAmount, -- Will be calculated
        0 AS CostAmount, -- Will be calculated
        0 AS GrossProfitAmount, -- Will be calculated
        0 AS NetProfitAmount, -- Will be calculated
        DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 365, '2023-01-01') AS OrderDate,
        CASE (ABS(CHECKSUM(NEWID())) % 4)
            WHEN 0 THEN 'Credit Card'
            WHEN 1 THEN 'Debit Card'
            WHEN 2 THEN 'PayPal'
            ELSE 'Wire Transfer'
        END AS PaymentMethod,
        CASE (ABS(CHECKSUM(NEWID())) % 3)
            WHEN 0 THEN 'Standard'
            WHEN 1 THEN 'Express'
            ELSE 'Overnight'
        END AS ShippingMethod;

    SET @Counter = @Counter + 1;
END;

-- Update calculated columns
UPDATE fact.FactSales
SET
    SalesAmount = (Quantity * UnitPrice) - DiscountAmount,
    CostAmount = Quantity * UnitCost,
    GrossProfitAmount = ((Quantity * UnitPrice) - DiscountAmount) - (Quantity * UnitCost),
    NetProfitAmount = ((Quantity * UnitPrice) - DiscountAmount) - (Quantity * UnitCost) - TaxAmount;
GO

PRINT 'Sample data loaded successfully';
PRINT 'Customers: 5';
PRINT 'Products: 5';
PRINT 'Stores: 5';
PRINT 'Employees: 5';
PRINT 'Promotions: 5';
PRINT 'Sales Records: 100';
GO
