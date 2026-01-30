# Azure Synapse Analytics Platform - Terraform Configuration

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "azurerm" {
    # Configure remote state storage
    # resource_group_name  = "terraform-state-rg"
    # storage_account_name = "tfstate"
    # container_name       = "tfstate"
    # key                  = "synapse-analytics-platform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Variables
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-synapse-analytics-platform"
}

variable "location" {
  description = "The Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "workspace_name" {
  description = "The name of the Synapse workspace"
  type        = string
  default     = "synapse-analytics-platform"
}

variable "sql_administrator_login" {
  description = "The administrator username for SQL pools"
  type        = string
  default     = "sqladmin"
  sensitive   = true
}

variable "sql_administrator_password" {
  description = "The administrator password for SQL pools"
  type        = string
  sensitive   = true
}

variable "dedicated_sql_pool_sku" {
  description = "The SKU for the dedicated SQL pool"
  type        = string
  default     = "DW100c"

  validation {
    condition     = contains(["DW100c", "DW200c", "DW300c", "DW400c", "DW500c", "DW1000c", "DW1500c", "DW2000c", "DW3000c"], var.dedicated_sql_pool_sku)
    error_message = "Invalid SQL pool SKU. Must be one of: DW100c, DW200c, DW300c, DW400c, DW500c, DW1000c, DW1500c, DW2000c, DW3000c"
  }
}

variable "spark_pool_node_size" {
  description = "The node size for the Spark pool"
  type        = string
  default     = "Small"

  validation {
    condition     = contains(["Small", "Medium", "Large"], var.spark_pool_node_size)
    error_message = "Invalid node size. Must be one of: Small, Medium, Large"
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "Synapse Analytics Platform"
    ManagedBy   = "Terraform"
  }
}

# Random suffix for unique names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "synapse_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Data Lake Storage Gen2
resource "azurerm_storage_account" "datalake" {
  name                     = "datalake${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.synapse_rg.name
  location                 = azurerm_resource_group.synapse_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

# Storage Container (File System)
resource "azurerm_storage_data_lake_gen2_filesystem" "synapsefs" {
  name               = "synapsefs"
  storage_account_id = azurerm_storage_account.datalake.id
}

# Synapse Workspace
resource "azurerm_synapse_workspace" "synapse" {
  name                                 = "${var.workspace_name}-${random_string.suffix.result}"
  resource_group_name                  = azurerm_resource_group.synapse_rg.name
  location                             = azurerm_resource_group.synapse_rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapsefs.id
  sql_administrator_login              = var.sql_administrator_login
  sql_administrator_login_password     = var.sql_administrator_password
  managed_virtual_network_enabled      = true
  public_network_access_enabled        = true

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Synapse Firewall Rules
resource "azurerm_synapse_firewall_rule" "allow_azure_services" {
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}

resource "azurerm_synapse_firewall_rule" "allow_all_ips" {
  name                 = "AllowAllIPs"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

# Dedicated SQL Pool
resource "azurerm_synapse_sql_pool" "dedicated_pool" {
  name                 = "EnterpriseDW"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  sku_name             = var.dedicated_sql_pool_sku
  create_mode          = "Default"
  collation            = "SQL_Latin1_General_CP1_CI_AS"

  tags = var.tags
}

# Spark Pool
resource "azurerm_synapse_spark_pool" "spark_pool" {
  name                 = "sparkpool"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  node_size_family     = "MemoryOptimized"
  node_size            = var.spark_pool_node_size

  auto_scale {
    min_node_count = 3
    max_node_count = 10
  }

  auto_pause {
    delay_in_minutes = 15
  }

  spark_version = "3.4"

  library_requirement {
    content  = file("${path.module}/spark-requirements.txt")
    filename = "requirements.txt"
  }

  tags = var.tags
}

# Role Assignment - Storage Blob Data Contributor
resource "azurerm_role_assignment" "synapse_storage_access" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.synapse.identity[0].principal_id
}

# Key Vault for secrets (optional but recommended)
resource "azurerm_key_vault" "synapse_kv" {
  name                       = "kv-synapse-${random_string.suffix.result}"
  location                   = azurerm_resource_group.synapse_rg.location
  resource_group_name        = azurerm_resource_group.synapse_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_synapse_workspace.synapse.identity[0].principal_id

    secret_permissions = [
      "Get",
      "List"
    ]
  }

  tags = var.tags
}

# Data source for current Azure client config
data "azurerm_client_config" "current" {}

# Outputs
output "workspace_name" {
  description = "The name of the Synapse workspace"
  value       = azurerm_synapse_workspace.synapse.name
}

output "workspace_id" {
  description = "The ID of the Synapse workspace"
  value       = azurerm_synapse_workspace.synapse.id
}

output "workspace_url" {
  description = "The development endpoint URL for the Synapse workspace"
  value       = "https://${azurerm_synapse_workspace.synapse.name}.dev.azuresynapse.net"
}

output "data_lake_account_name" {
  description = "The name of the Data Lake Storage account"
  value       = azurerm_storage_account.datalake.name
}

output "dedicated_sql_pool_name" {
  description = "The name of the dedicated SQL pool"
  value       = azurerm_synapse_sql_pool.dedicated_pool.name
}

output "spark_pool_name" {
  description = "The name of the Spark pool"
  value       = azurerm_synapse_spark_pool.spark_pool.name
}

output "sql_server_endpoint" {
  description = "The SQL server endpoint"
  value       = "${azurerm_synapse_workspace.synapse.name}.sql.azuresynapse.net"
}

output "sql_ondemand_endpoint" {
  description = "The SQL serverless (on-demand) endpoint"
  value       = "${azurerm_synapse_workspace.synapse.name}-ondemand.sql.azuresynapse.net"
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.synapse_kv.name
}

output "workspace_principal_id" {
  description = "The principal ID of the Synapse workspace managed identity"
  value       = azurerm_synapse_workspace.synapse.identity[0].principal_id
}
