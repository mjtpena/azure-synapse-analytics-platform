# Power BI Integration Guide

This directory contains Power BI dataset definitions and connection files for connecting to Azure Synapse Analytics.

## Files

- `SynapseConnection.pbids` - Power BI Data Source file for direct connection
- `SampleReport.pbit` - Sample Power BI template
- `DatasetDefinitions.json` - Dataset definitions for programmatic deployment

## Connecting Power BI to Synapse

### Option 1: Using .pbids File

1. Update `SynapseConnection.pbids` with your Synapse workspace name
2. Double-click the file to open in Power BI Desktop
3. Authenticate using Azure AD
4. Select tables/views to import or use DirectQuery

### Option 2: Manual Connection

1. Open Power BI Desktop
2. Get Data > Azure > Azure Synapse Analytics SQL
3. Enter server: `your-workspace-name.sql.azuresynapse.net`
4. Enter database: `EnterpriseDW`
5. Choose authentication method:
   - Azure Active Directory (recommended)
   - SQL Server Authentication
6. Select DirectQuery or Import mode

## Recommended Views for Reporting

The following views are optimized for Power BI:

### Sales Analysis
- `views.vw_SalesSummary` - Complete sales data with all dimensions
- `views.vw_ProductPerformance` - Product-level metrics
- `views.vw_StorePerformance` - Store-level metrics

### Customer Analytics
- `views.vw_CustomerAnalytics` - Customer segmentation and RFM scores
- `fact.FactCustomerActivity` - Customer lifetime value metrics

### Inventory Management
- `views.vw_InventoryAnalysis` - Current inventory status and health

### Web Analytics
- `views.vw_WebAnalyticsSummary` - Web traffic and conversion metrics

## DirectQuery vs Import Mode

### DirectQuery (Recommended)
**Pros:**
- Always current data
- No data size limits
- Centralized security

**Cons:**
- Slower query performance
- Limited DAX functions
- Requires Synapse to be running

**Best for:** Real-time dashboards, large datasets

### Import Mode
**Pros:**
- Fast query performance
- Full DAX support
- Offline access

**Cons:**
- Data refresh required
- Size limitations (1-10 GB)
- Duplicate data storage

**Best for:** Static reports, small datasets

## Performance Optimization

### 1. Use Aggregations
Create aggregation tables in Synapse for better performance:
```sql
CREATE TABLE agg.SalesDaily
WITH (DISTRIBUTION = HASH(DateKey))
AS
SELECT
    DateKey,
    CustomerKey,
    ProductKey,
    SUM(Quantity) as TotalQuantity,
    SUM(SalesAmount) as TotalSales
FROM fact.FactSales
GROUP BY DateKey, CustomerKey, ProductKey;
```

### 2. Implement Composite Models
- Use DirectQuery for large fact tables
- Import dimension tables for better performance
- Create aggregations for common queries

### 3. Optimize DAX Queries
- Use SUMMARIZECOLUMNS instead of SUMMARIZE
- Avoid iterating functions (e.g., SUMX) in DirectQuery
- Use variables to reduce query complexity

### 4. Enable Query Folding
- Avoid custom columns in Power Query
- Use SQL views for transformations
- Minimize M query transformations

## Security

### Row-Level Security (RLS)

Implement RLS in Synapse SQL Pool:

```sql
-- Create security policy
CREATE SECURITY POLICY RegionSecurityPolicy
ADD FILTER PREDICATE security.fn_securitypredicate(Region)
ON views.vw_SalesSummary
WITH (STATE = ON);

-- Create security function
CREATE FUNCTION security.fn_securitypredicate(@Region AS nvarchar(100))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS result
WHERE @Region = USER_NAME() OR USER_NAME() = 'admin';
```

### Object-Level Security

Grant permissions at the view level:

```sql
-- Grant read access to views
GRANT SELECT ON SCHEMA::views TO PowerBIRole;

-- Deny access to base tables
DENY SELECT ON SCHEMA::fact TO PowerBIRole;
DENY SELECT ON SCHEMA::dim TO PowerBIRole;
```

## Data Refresh Schedule

### For Import Mode:

1. **Power BI Service:**
   - Configure scheduled refresh in workspace settings
   - Set up gateway if using on-premises data
   - Schedule refresh during off-peak hours

2. **Refresh Frequency:**
   - Sales data: Every 1 hour
   - Customer data: Daily at 2 AM
   - Product data: Daily at 3 AM

### For DirectQuery:

No refresh needed - data is always current

## Monitoring and Troubleshooting

### Common Issues

1. **Slow Performance:**
   - Check Synapse SQL Pool performance level
   - Review query execution plans
   - Implement aggregations
   - Consider switching to Import mode for small datasets

2. **Connection Timeouts:**
   - Increase timeout settings in Power BI
   - Pause/resume SQL Pool
   - Check firewall rules

3. **Authentication Errors:**
   - Verify Azure AD permissions
   - Check SQL Pool firewall rules
   - Update credentials in Power BI Service

### Query Diagnostics

Enable query diagnostics in Power BI Desktop:
1. Options > Diagnostics
2. Enable "Enable tracing"
3. Review generated trace files

## Best Practices

1. **Data Modeling:**
   - Use star schema design
   - Create relationships at the database level
   - Minimize calculated columns in Power BI

2. **Report Design:**
   - Limit visuals per page (< 10)
   - Use bookmarks for complex interactions
   - Implement incremental refresh for large tables

3. **Deployment:**
   - Use deployment pipelines (Dev > Test > Prod)
   - Version control report templates
   - Document data lineage

4. **Governance:**
   - Implement data classification
   - Use sensitivity labels
   - Enable audit logging

## Sample DAX Measures

```dax
// Total Sales
Total Sales = SUM(vw_SalesSummary[SalesAmount])

// Year-over-Year Growth
YoY Sales Growth =
VAR CurrentYearSales = [Total Sales]
VAR PreviousYearSales =
    CALCULATE(
        [Total Sales],
        DATEADD(DimDate[FullDate], -1, YEAR)
    )
RETURN
    DIVIDE(CurrentYearSales - PreviousYearSales, PreviousYearSales)

// Customer Lifetime Value
Customer LTV =
CALCULATE(
    SUM(vw_CustomerAnalytics[LifetimeValue]),
    ALLEXCEPT(vw_CustomerAnalytics, vw_CustomerAnalytics[CustomerID])
)

// Moving Average (3 months)
Sales 3M MA =
AVERAGEX(
    DATESINPERIOD(
        DimDate[FullDate],
        LASTDATE(DimDate[FullDate]),
        -3,
        MONTH
    ),
    [Total Sales]
)
```

## Resources

- [Power BI Documentation](https://docs.microsoft.com/power-bi/)
- [Synapse Analytics Documentation](https://docs.microsoft.com/azure/synapse-analytics/)
- [DirectQuery Best Practices](https://docs.microsoft.com/power-bi/connect-data/desktop-directquery-about)
- [DAX Reference](https://dax.guide/)
