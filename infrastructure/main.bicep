// Azure Synapse Analytics Platform - Main Bicep Template
// This template deploys a complete Synapse Analytics environment with SQL pools, Spark pools, and Power BI integration

targetScope = 'resourceGroup'

@description('The name of the Synapse workspace')
param workspaceName string = 'synapse-${uniqueString(resourceGroup().id)}'

@description('The location for all resources')
param location string = resourceGroup().location

@description('The administrator username for SQL pools')
param sqlAdministratorLogin string = 'sqladmin'

@description('The administrator password for SQL pools')
@secure()
param sqlAdministratorPassword string

@description('The name of the Data Lake Storage Gen2 account')
param dataLakeAccountName string = 'datalake${uniqueString(resourceGroup().id)}'

@description('The name of the dedicated SQL pool')
param dedicatedSqlPoolName string = 'EnterpriseDW'

@description('The SKU for the dedicated SQL pool')
@allowed([
  'DW100c'
  'DW200c'
  'DW300c'
  'DW400c'
  'DW500c'
  'DW1000c'
  'DW1500c'
  'DW2000c'
  'DW3000c'
])
param dedicatedSqlPoolSku string = 'DW100c'

@description('The name of the Spark pool')
param sparkPoolName string = 'sparkpool'

@description('The node size for the Spark pool')
@allowed([
  'Small'
  'Medium'
  'Large'
])
param sparkPoolNodeSize string = 'Small'

@description('Enable Power BI workspace integration')
param enablePowerBIIntegration bool = true

@description('Tags to apply to all resources')
param tags object = {
  Environment: 'Development'
  Project: 'Synapse Analytics Platform'
  ManagedBy: 'Bicep'
}

// Variables
var dataLakeFileSystemName = 'synapsefs'
var managedResourceGroupName = 'synapse-managed-rg-${uniqueString(resourceGroup().id)}'

// Data Lake Storage Gen2 Account
resource dataLakeAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: dataLakeAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Blob Service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: dataLakeAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// File System (Container)
resource fileSystem 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: dataLakeFileSystemName
  properties: {
    publicAccess: 'None'
  }
}

// Synapse Workspace
resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: dataLakeAccount.properties.primaryEndpoints.dfs
      filesystem: dataLakeFileSystemName
    }
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorPassword
    managedResourceGroupName: managedResourceGroupName
    publicNetworkAccess: 'Enabled'
    managedVirtualNetwork: 'default'
    trustedServiceBypassEnabled: true
  }
}

// Firewall Rules - Allow all Azure services
resource allowAllAzureIPs 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  parent: synapseWorkspace
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Firewall Rules - Allow all IPs (for development only)
resource allowAllIPs 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  parent: synapseWorkspace
  name: 'AllowAllIPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

// Dedicated SQL Pool
resource dedicatedSqlPool 'Microsoft.Synapse/workspaces/sqlPools@2021-06-01' = {
  parent: synapseWorkspace
  name: dedicatedSqlPoolName
  location: location
  tags: tags
  sku: {
    name: dedicatedSqlPoolSku
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    createMode: 'Default'
    storageAccountType: 'LRS'
  }
}

// Spark Pool
resource sparkPool 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  parent: synapseWorkspace
  name: sparkPoolName
  location: location
  tags: tags
  properties: {
    nodeCount: 3
    nodeSizeFamily: 'MemoryOptimized'
    nodeSize: sparkPoolNodeSize
    autoScale: {
      enabled: true
      minNodeCount: 3
      maxNodeCount: 10
    }
    autoPause: {
      enabled: true
      delayInMinutes: 15
    }
    sparkVersion: '3.4'
    dynamicExecutorAllocation: {
      enabled: true
      minExecutors: 1
      maxExecutors: 10
    }
    cacheSize: 50
    sessionLevelPackagesEnabled: true
  }
}

// Grant Storage Blob Data Contributor role to Synapse workspace MI
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(dataLakeAccount.id, synapseWorkspace.id, 'StorageBlobDataContributor')
  scope: dataLakeAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: synapseWorkspace.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output workspaceName string = synapseWorkspace.name
output workspaceId string = synapseWorkspace.id
output workspaceUrl string = 'https://${synapseWorkspace.name}.dev.azuresynapse.net'
output dataLakeAccountName string = dataLakeAccount.name
output dedicatedSqlPoolName string = dedicatedSqlPool.name
output sparkPoolName string = sparkPool.name
output workspacePrincipalId string = synapseWorkspace.identity.principalId
output sqlServerEndpoint string = '${synapseWorkspace.name}.sql.azuresynapse.net'
output sqlOnDemandEndpoint string = '${synapseWorkspace.name}-ondemand.sql.azuresynapse.net'
