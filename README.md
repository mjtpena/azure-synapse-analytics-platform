# Azure Synapse Analytics Platform

A comprehensive enterprise data warehouse solution built on Azure Synapse Analytics, featuring automated ETL pipelines, dimensional modeling, and Power BI integration.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Data Sources                                 │
│  CSV Files  │  JSON Files  │  SQL Databases  │  APIs  │  Streaming  │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Azure Data Lake Gen2                             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    │
│  │   Raw    │───▶│  Bronze  │───▶│  Silver  │───▶│   Gold   │    │
│  │  (CSV,   │    │ (Parquet)│    │  (Delta) │    │(Analytics)│   │
│  │   JSON)  │    │          │    │          │    │          │    │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘    │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Azure Synapse Workspace                            │
│  ┌───────────────────┐  ┌─────────────────┐  ┌──────────────────┐ │
│  │  Spark Pools      │  │  SQL Pools      │  │   Pipelines      │ │
│  │  - Ingestion      │  │  - Star Schema  │  │  - Orchestration │ │
│  │  - Transformation │  │  - SCD Type 2   │  │  - Scheduling    │ │
│  │  - ML Processing  │  │  - Aggregations │  │  - Monitoring    │ │
│  └───────────────────┘  └─────────────────┘  └──────────────────┘ │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Analytics & Reporting                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │
│  │  Power BI   │  │   Tableau   │  │    Excel    │  │  Python   │ │
│  │ Dashboards  │  │   Reports   │  │   Exports   │  │  Jupyter  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └───────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Features

### Infrastructure
- **Infrastructure as Code**: Complete Bicep and Terraform templates
- **Automated Deployment**: Shell scripts for one-click deployment
- **Multi-environment Support**: Dev, Test, and Production configurations
- **Cost Optimization**: Auto-pause SQL pools, dynamic Spark scaling

### Data Warehouse
- **Star Schema Design**: Optimized dimensional model
- **SCD Type 2**: Slowly changing dimensions with history tracking
- **Partitioning**: Date-based partitioning for performance
- **Distributed Tables**: Hash distribution for large fact tables
- **Replicated Tables**: Small dimension tables for query optimization

### ETL Pipelines
- **Master Orchestration**: End-to-end ETL automation
- **Incremental Loading**: Watermark-based change data capture
- **Data Quality**: Built-in validation and quality checks
- **Error Handling**: Retry logic and notification system
- **Monitoring**: Pipeline run metrics and logging

### Analytics
- **Pre-built Views**: Optimized for reporting
- **Customer Segmentation**: RFM analysis and lifetime value
- **Product Analytics**: Sales performance and profitability
- **Inventory Management**: Stock levels and alerts
- **Web Analytics**: Traffic, conversions, and user behavior

### Integration
- **Power BI**: Direct connection and sample datasets
- **REST API**: Comprehensive API testing suite
- **CI/CD**: GitHub Actions workflows
- **Security**: Azure AD authentication and RBAC

## Project Structure

```
azure-synapse-analytics-platform/
├── infrastructure/              # IaC templates
│   ├── main.bicep              # Bicep deployment template
│   ├── main.tf                 # Terraform configuration
│   ├── parameters.json         # Deployment parameters
│   ├── terraform.tfvars.example # Terraform variables
│   └── deploy.sh               # Deployment script
├── sql/                        # SQL scripts
│   ├── 01_create_schemas.sql
│   ├── 02_create_dimension_tables.sql
│   ├── 03_create_fact_tables.sql
│   ├── 04_create_stored_procedures.sql
│   ├── 05_create_views.sql
│   └── 06_sample_data.sql
├── notebooks/                  # Spark notebooks
│   ├── 01_data_ingestion.ipynb
│   ├── 02_data_transformation.ipynb
│   └── 03_load_to_sql_pool.ipynb
├── pipelines/                  # Synapse pipelines
│   ├── pl_master_etl_pipeline.json
│   ├── pl_data_ingestion.json
│   └── pl_incremental_load.json
├── tests/                      # API tests
│   ├── test_synapse_api.py
│   ├── conftest.py
│   ├── requirements.txt
│   └── .env.example
├── powerbi/                    # Power BI assets
│   ├── SynapseConnection.pbids
│   ├── DatasetDefinitions.json
│   └── README.md
├── .github/workflows/          # CI/CD workflows
│   ├── deploy-infrastructure.yml
│   ├── deploy-sql-objects.yml
│   └── run-tests.yml
└── README.md
```

## Prerequisites

- Azure subscription with contributor access
- Azure CLI installed (`az --version`)
- Terraform installed (for Terraform deployment)
- Python 3.8+ (for API tests)
- Power BI Desktop (for reporting)
- Git installed

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/azure-synapse-analytics-platform.git
cd azure-synapse-analytics-platform
```

### 2. Deploy Infrastructure

#### Option A: Using Bicep

```bash
cd infrastructure

# Login to Azure
az login

# Set variables
RESOURCE_GROUP="rg-synapse-analytics-platform"
LOCATION="eastus"
WORKSPACE_NAME="synapse-analytics-$(openssl rand -hex 4)"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy Bicep template
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters \
    workspaceName=$WORKSPACE_NAME \
    sqlAdministratorLogin="sqladmin" \
    sqlAdministratorPassword="YourSecurePassword123!"
```

#### Option B: Using Terraform

```bash
cd infrastructure

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

#### Option C: Using Deployment Script

```bash
cd infrastructure
chmod +x deploy.sh
./deploy.sh
```

### 3. Deploy SQL Objects

```bash
# Connect to SQL Pool using Azure Data Studio or SSMS
# Server: your-workspace-name.sql.azuresynapse.net
# Database: EnterpriseDW
# Authentication: Azure Active Directory

# Run SQL scripts in order:
cd sql
# Execute: 01_create_schemas.sql
# Execute: 02_create_dimension_tables.sql
# Execute: 03_create_fact_tables.sql
# Execute: 04_create_stored_procedures.sql
# Execute: 05_create_views.sql
# Execute: 06_sample_data.sql (optional)
```

### 4. Upload Notebooks

1. Navigate to Synapse Studio (https://your-workspace-name.dev.azuresynapse.net)
2. Go to Develop > Notebooks
3. Click "+" > Import
4. Upload notebooks from `notebooks/` directory

### 5. Create Pipelines

1. In Synapse Studio, go to Integrate > Pipelines
2. Click "+" > Import from pipeline template
3. Import pipeline JSON files from `pipelines/` directory

### 6. Run API Tests

```bash
cd tests

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Run tests
pytest test_synapse_api.py -v
```

### 7. Connect Power BI

1. Open `powerbi/SynapseConnection.pbids`
2. Update with your workspace name
3. Double-click to open in Power BI Desktop
4. Authenticate with Azure AD
5. Select views from the `views` schema

## Data Model

### Dimension Tables

- **dim.DimDate** - Date dimension with fiscal calendar
- **dim.DimCustomer** - Customer master (SCD Type 2)
- **dim.DimProduct** - Product catalog (SCD Type 2)
- **dim.DimStore** - Store/location information (SCD Type 2)
- **dim.DimEmployee** - Employee information (SCD Type 2)
- **dim.DimPromotion** - Promotional campaigns

### Fact Tables

- **fact.FactSales** - Sales transactions (transactional)
- **fact.FactInventory** - Inventory snapshots (periodic)
- **fact.FactCustomerActivity** - Customer metrics (accumulating)
- **fact.FactWebAnalytics** - Web activity (transactional)

### Views

- **views.vw_SalesSummary** - Complete sales analysis
- **views.vw_CustomerAnalytics** - Customer segmentation
- **views.vw_ProductPerformance** - Product metrics
- **views.vw_StorePerformance** - Store metrics
- **views.vw_InventoryAnalysis** - Inventory health
- **views.vw_WebAnalyticsSummary** - Web metrics

## ETL Process

### 1. Data Ingestion (Bronze Layer)
- Copy data from sources to Data Lake
- Store in Parquet format
- Add audit columns (ingestion date, source file)

### 2. Data Transformation (Silver Layer)
- Clean and standardize data
- Apply business rules
- Perform data quality checks
- Store in Delta format

### 3. Load to SQL Pool (Gold Layer)
- Implement SCD Type 2 for dimensions
- Load fact tables with surrogate keys
- Update aggregation tables
- Refresh statistics

### 4. Post-Processing
- Calculate customer RFM scores
- Update materialized views
- Send completion notifications

## Pipeline Execution

### Manual Trigger
```bash
# Using Azure CLI
az synapse pipeline create-run \
  --workspace-name your-workspace-name \
  --name pl_master_etl_pipeline
```

### Scheduled Trigger
Configure in Synapse Studio:
1. Go to Manage > Triggers
2. Create new schedule trigger
3. Set recurrence (daily, hourly, etc.)
4. Associate with pipeline

### Event-Based Trigger
Configure blob event trigger:
1. Create trigger on storage account
2. Filter for file arrival events
3. Trigger pipeline automatically

## Monitoring

### Azure Monitor
- Query run history and durations
- Set up alerts for failures
- Monitor resource utilization

### Synapse Studio
- View pipeline runs and activity details
- Check Spark job execution
- Monitor SQL pool performance

### Log Analytics
```kusto
// Query pipeline failures
SynapsePipelineRuns
| where Status == "Failed"
| project TimeGenerated, PipelineName, RunId, ErrorMessage
| order by TimeGenerated desc
```

## Security

### Authentication
- Azure Active Directory integration
- Managed Identity for resource access
- Service Principal for CI/CD

### Authorization
- Role-Based Access Control (RBAC)
- SQL-level permissions
- Row-Level Security (RLS) in views

### Network Security
- Private endpoints for secure access
- Firewall rules configuration
- Virtual network integration

### Data Protection
- Encryption at rest (default)
- Encryption in transit (TLS 1.2)
- Data masking for sensitive fields

## Cost Optimization

### SQL Pool
```bash
# Pause when not in use
az synapse sql pool pause --name EnterpriseDW --workspace-name your-workspace

# Resume when needed
az synapse sql pool resume --name EnterpriseDW --workspace-name your-workspace
```

### Spark Pool
- Configure auto-pause (15 minutes idle)
- Use auto-scaling (3-10 nodes)
- Right-size node selection

### Storage
- Use lifecycle management policies
- Archive old data to Cool/Archive tiers
- Implement data retention policies

### Monitoring
- Set up budget alerts
- Review Cost Analysis regularly
- Use Azure Advisor recommendations

## Troubleshooting

### Common Issues

#### SQL Pool Connection Timeouts
```bash
# Check SQL Pool status
az synapse sql pool show \
  --name EnterpriseDW \
  --workspace-name your-workspace \
  --resource-group your-rg

# Check firewall rules
az synapse workspace firewall-rule list \
  --workspace-name your-workspace \
  --resource-group your-rg
```

#### Pipeline Failures
1. Check pipeline run details in Synapse Studio
2. Review activity error messages
3. Validate linked service connections
4. Check data source availability

#### Performance Issues
1. Update statistics: `EXEC etl.RefreshStatistics`
2. Check query plans for missing indexes
3. Review distribution and partitioning
4. Consider increasing SQL Pool DWU

## CI/CD

### GitHub Actions Workflows

The project includes three workflows:

1. **deploy-infrastructure.yml** - Deploys Azure resources
2. **deploy-sql-objects.yml** - Deploys SQL schemas and objects
3. **run-tests.yml** - Runs API tests

### Setup

1. Configure GitHub secrets:
   - `AZURE_CREDENTIALS`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_RESOURCE_GROUP`
   - `SQL_ADMIN_PASSWORD`

2. Push to main branch to trigger deployment

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [Azure Synapse Analytics Documentation](https://docs.microsoft.com/azure/synapse-analytics/)
- [Synapse SQL Best Practices](https://docs.microsoft.com/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-best-practices)
- [Power BI Documentation](https://docs.microsoft.com/power-bi/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)

## Support

For issues and questions:
- Open an issue on GitHub
- Contact the maintainers
- Check the documentation

## Acknowledgments

- Microsoft Azure Synapse team for excellent documentation
- Community contributors
- Open source tools and libraries used in this project
