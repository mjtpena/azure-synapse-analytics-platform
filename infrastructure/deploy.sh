#!/bin/bash
# Deployment script for Azure Synapse Analytics Platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Azure Synapse Analytics Platform Deployment${NC}"
echo "=============================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Please log in...${NC}"
    az login
fi

# Get current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${GREEN}Current subscription: ${SUBSCRIPTION}${NC}"

# Prompt for deployment method
echo ""
echo "Choose deployment method:"
echo "1) Bicep"
echo "2) Terraform"
read -p "Enter choice [1-2]: " DEPLOY_METHOD

if [ "$DEPLOY_METHOD" == "1" ]; then
    echo -e "${GREEN}Deploying with Bicep...${NC}"

    # Prompt for parameters
    read -p "Enter resource group name (default: rg-synapse-analytics-platform): " RG_NAME
    RG_NAME=${RG_NAME:-rg-synapse-analytics-platform}

    read -p "Enter location (default: eastus): " LOCATION
    LOCATION=${LOCATION:-eastus}

    read -p "Enter workspace name (default: synapse-analytics-platform): " WORKSPACE_NAME
    WORKSPACE_NAME=${WORKSPACE_NAME:-synapse-analytics-platform}

    read -p "Enter SQL admin username (default: sqladmin): " SQL_ADMIN
    SQL_ADMIN=${SQL_ADMIN:-sqladmin}

    read -sp "Enter SQL admin password: " SQL_PASSWORD
    echo ""

    # Create resource group
    echo -e "${GREEN}Creating resource group...${NC}"
    az group create --name $RG_NAME --location $LOCATION

    # Validate template
    echo -e "${GREEN}Validating Bicep template...${NC}"
    az deployment group validate \
        --resource-group $RG_NAME \
        --template-file main.bicep \
        --parameters \
            workspaceName=$WORKSPACE_NAME \
            sqlAdministratorLogin=$SQL_ADMIN \
            sqlAdministratorPassword=$SQL_PASSWORD \
            location=$LOCATION

    # Deploy template
    echo -e "${GREEN}Deploying Bicep template...${NC}"
    az deployment group create \
        --resource-group $RG_NAME \
        --template-file main.bicep \
        --parameters \
            workspaceName=$WORKSPACE_NAME \
            sqlAdministratorLogin=$SQL_ADMIN \
            sqlAdministratorPassword=$SQL_PASSWORD \
            location=$LOCATION \
        --name synapse-deployment-$(date +%Y%m%d-%H%M%S)

    echo -e "${GREEN}Deployment completed successfully!${NC}"

    # Show outputs
    echo -e "${GREEN}Deployment outputs:${NC}"
    az deployment group show \
        --resource-group $RG_NAME \
        --name synapse-deployment-$(date +%Y%m%d-%H%M%S) \
        --query properties.outputs

elif [ "$DEPLOY_METHOD" == "2" ]; then
    echo -e "${GREEN}Deploying with Terraform...${NC}"

    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Terraform is not installed. Please install it first.${NC}"
        exit 1
    fi

    # Check if terraform.tfvars exists
    if [ ! -f terraform.tfvars ]; then
        echo -e "${YELLOW}terraform.tfvars not found. Please create it from terraform.tfvars.example${NC}"
        exit 1
    fi

    # Initialize Terraform
    echo -e "${GREEN}Initializing Terraform...${NC}"
    terraform init

    # Validate configuration
    echo -e "${GREEN}Validating Terraform configuration...${NC}"
    terraform validate

    # Plan deployment
    echo -e "${GREEN}Planning Terraform deployment...${NC}"
    terraform plan -out=tfplan

    # Prompt for confirmation
    read -p "Do you want to apply this plan? (yes/no): " CONFIRM
    if [ "$CONFIRM" == "yes" ]; then
        echo -e "${GREEN}Applying Terraform plan...${NC}"
        terraform apply tfplan

        echo -e "${GREEN}Deployment completed successfully!${NC}"

        # Show outputs
        echo -e "${GREEN}Deployment outputs:${NC}"
        terraform output
    else
        echo -e "${YELLOW}Deployment cancelled.${NC}"
    fi
else
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Navigate to Azure Portal to verify resources"
echo "2. Configure firewall rules if needed"
echo "3. Deploy SQL scripts from the sql/ directory"
echo "4. Upload and run Spark notebooks"
echo "5. Configure and run pipelines"
echo "6. Connect Power BI to the SQL pools"
