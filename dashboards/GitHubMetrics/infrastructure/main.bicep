@description('Base name to be used in all resources')
param name string = ''

@description('Name of the datalake account')
param dlsname string = ''

@description('Location where resources should be deployed')
param location string = resourceGroup().location

var version = 'CCOInsights v0.1'

// Registry
module registry 'br/public:avm/res/container-registry/registry:0.9.1' = {
  name: '${name}-cco-registry'
  params: {
    name: toLower('${name}ccoregistry')
    acrSku: 'Standard'
    location: location
    tags: {
      version: version
    }
  }
}

// App Service Plan
module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: '${name}-cco-gh-sp'
  params: {
    name: '${name}-cco-gh-sp'
    location: location
    skuCapacity: 1
    skuName: 'B1'
    tags: {
      version: version
    }
    kind: 'linux'
  }
}

// Log Analytics Workspace
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: '${name}-cco-la'
  params: {
    name: '${name}-cco-la'
    location: location
    tags: {
      version: version
    }
  }
}

// Application Insights
module appInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: '${name}-cco-ai'
  params: {
    name: '${name}-cco-ai'
    location: location
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    kind: 'web'
    tags: {
      version: version
    }
  }
}


// Web App
module appService 'br/public:avm/res/web/site:0.16.0' = {
  name: '${name}-cco-gh-app'
  params: {
    name: '${name}-cco-gh-app'
    location: location
    kind: 'app,linux,container'
    serverFarmResourceId: appServicePlan.outputs.resourceId

    managedIdentities: {
      systemAssigned: true
    }
    siteConfig: {
      alwaysOn: true
      use32BitWorkerProcess: false
      linuxFxVersion: 'DOCKER|${registry.outputs.loginServer}/github-metrics:latest'
      minTlsVersion: '1.2'
      acrUseManagedIdentityCreds: true
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
        supportCredentials: false
      }    }
    configs: [
      {
        name: 'appsettings'
        properties: {
          APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.outputs.connectionString
          ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
          STORAGE_ACCOUNT_NAME: dataLakeStorage.outputs.name
          ACR_LOGIN_SERVER: registry.outputs.loginServer
          WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
        }
      }
    ]
    httpsOnly: true
    tags: {
      version: version
    }
  }
}

// Data Lake Storage Account
module dataLakeStorage 'br/public:avm/res/storage/storage-account:0.25.0' = {
  name: !empty(dlsname) ? toLower(dlsname) : toLower('${name}ccodls')
  params: {
    name: !empty(dlsname) ? toLower(dlsname) : toLower('${name}ccodls')
    location: location
    enableHierarchicalNamespace: true
    skuName: 'Standard_LRS'
    // publicNetworkAccess: 'Enabled'
    publicNetworkAccess: 'Disabled' // For security, disable public access
    tags: {
      version: version
    }
  }
}

// ACR Role Assignment - Allow Web App to pull images
module acrRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: '${name}-acr-pull-ra'
  params: {
    name: guid(registry.outputs.resourceId, appService.outputs.systemAssignedMIPrincipalId!, 'AcrPull')
    principalId: appService.outputs.systemAssignedMIPrincipalId!
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull role
    principalType: 'ServicePrincipal'
    resourceId: registry.outputs.resourceId
  }
}

// Storage Table Role Assignment - Allow Web App to read/write table data
module storageTableRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: '${name}-storage-table-ra'
  params: {
    name: guid(dataLakeStorage.outputs.resourceId, appService.outputs.systemAssignedMIPrincipalId!, 'StorageTableDataContributor')
    principalId: appService.outputs.systemAssignedMIPrincipalId!
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' // Storage Table Data Contributor role
    principalType: 'ServicePrincipal'
    resourceId: dataLakeStorage.outputs.resourceId
  }
}

// Outputs
output registryLoginServer string = registry.outputs.loginServer
