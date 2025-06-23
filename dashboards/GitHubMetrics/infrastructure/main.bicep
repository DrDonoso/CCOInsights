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
  }
}

// App Service Plan
module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: '${name}-cco-sp'
  params: {
    name: '${name}-cco-sp'
    location: location
    skuCapacity: 1
    skuName: 'B1'
    tags: {
      version: version
    }
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


// Function App
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
      minimumElasticInstanceCount: 1
      functionAppScaleLimit: 200
      netFrameworkVersion: 'v8.0'
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
        supportCredentials: false
      }
      linuxFxVersion: 'DOCKER|${registry.outputs.loginServer}/cco-gh-app:latest'
      minTlsVersion: '1.2'
    }
    configs: [
      {
        name: 'appsettings'
        properties: {
          FUNCTIONS_EXTENSION_VERSION: '~4'
          FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
          WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED: '1'
        }
        applicationInsightResourceId: appInsights.outputs.resourceId
      }
    ]
    httpsOnly: true
    tags: {
      version: version
    }
  }
}

// Data Lake Storage Account
module dataLakeStorage 'br/public:avm/res/storage/storage-account:0.20.0' = {
  name: !empty(dlsname) ? toLower(dlsname) : toLower('${name}ccodls')
  params: {
    name: !empty(dlsname) ? toLower(dlsname) : toLower('${name}ccodls')
    location: location
    enableHierarchicalNamespace: true
    skuName: 'Standard_LRS'
    publicNetworkAccess: 'Enabled'
    tags: {
      version: version
    }
  }
}

module roleAssignment1 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: '${name}-storage-ra'
  params: {
    name: guid(name, 'Contributor')
    principalId: appService.outputs.?systemAssignedMIPrincipalId!
    roleName: 'Contributor'
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor role
    principalType: 'ServicePrincipal'
    resourceId: dataLakeStorage.outputs.resourceId
  }
}
 
module roleAssignment2 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: '${name}-storage-ra2'
  params: {
    name: guid(resourceGroup().id, 'StorageBlobDataContributor')
    principalId: appService.outputs.?systemAssignedMIPrincipalId!
    roleName: 'Contributor'
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor role
    principalType: 'ServicePrincipal'
    resourceId: dataLakeStorage.outputs.resourceId
  }
}
