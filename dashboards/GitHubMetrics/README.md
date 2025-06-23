# GitHubMetrics Bicep Template

This Bicep template provisions the core infrastructure for the CCO Insights GitHub Metrics solution in Azure. It deploys the following resources:

- Container Registry
- App Service Plan
- Azure Function App (with managed identity and container support)
- Log Analytics Workspace
- Application Insights
- Data Lake Storage Account (with hierarchical namespace)
- Role Assignments for secure access

## Parameters

| Name      | Type   | Description                                      | Default                |
|-----------|--------|--------------------------------------------------|------------------------|
| name      | string | Base name to be used in all resources            | (empty)                |
| dlsname   | string | Name of the datalake account                     | (empty)                |
| location  | string | Location where resources should be deployed      | resourceGroup().location |

## Modules and Resources

| Resource/Module                | Type/Module Path                                                      | Purpose/Features                                                                 | Version   |
|------------------------------- |-----------------------------------------------------------------------|----------------------------------------------------------------------------------|-----------|
| **Container Registry**         | `br/public:avm/res/container-registry/registry`                       | Hosts Docker containers for the solution. SKU: Standard.                        | 0.9.1     |
| **App Service Plan**           | `br/public:avm/res/web/serverfarm`                                    | Hosts the Azure Function App. SKU: B1 (Basic). Includes versioning tags.         | 0.4.1     |
| **Log Analytics Workspace**    | `br/public:avm/res/operational-insights/workspace`                    | Centralized logging and monitoring.                                              | 0.9.1     |
| **Application Insights**       | `br/public:avm/res/insights/component`                                | Application performance monitoring. Linked to Log Analytics Workspace.            | 0.6.0     |
| **Azure Function App**         | `br/public:avm/res/web/site`                                          | Backend logic. Managed identity, Linux container support, .NET 8 isolated.       | 0.16.0    |
| **Data Lake Storage Account**  | `br/public:avm/res/storage/storage-account`                           | Analytics storage. Hierarchical namespace, Standard_LRS SKU.                     | 0.20.0    |
| **Role Assignments**           | `br/public:avm/ptn/authorization/resource-role-assignment`            | Grants Function App MI Contributor and Storage Blob Data Contributor roles.        | 0.1.2     |

## Key Features

### Container Registry
- **SKU**: Standard tier for production workloads
- **Purpose**: Stores and manages Docker container images for the GitHub metrics application
- **Integration**: Configured with the Function App for seamless container deployment

### Function App Configuration
- **Runtime**: .NET 8 isolated worker process
- **Container Support**: Linux-based with Docker container deployment
- **Scaling**: Elastic scaling with minimum instance count of 1, maximum of 200
- **Security**: HTTPS only, TLS 1.2 minimum, CORS enabled for Azure portal
- **Monitoring**: Integrated with Application Insights for telemetry

### Data Lake Storage
- **Hierarchical Namespace**: Enabled for big data analytics scenarios
- **Access**: Public network access enabled
- **Redundancy**: Standard Locally Redundant Storage (LRS)
- **Integration**: Function App has Contributor and Storage Blob Data Contributor permissions

## Outputs

| Name                | Type   | Description                       |
|---------------------|--------|-----------------------------------|
| dataLakeStorageName | string | Name of the Data Lake Storage     |

## Usage

Deploy this template using Azure CLI:

```bash
az deployment group create \
  --resource-group <your-rg> \
  --template-file main.bicep \
  --parameters name=<base-name> dlsname=<datalake-name>
```

Or using Azure PowerShell:

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "<your-rg>" `
  -TemplateFile "main.bicep" `
  -name "<base-name>" `
  -dlsname "<datalake-name>"
```

## Prerequisites

- Azure subscription with appropriate permissions
- Resource group created
- Docker container image built and available for deployment

## Architecture Notes

This template creates a containerized Azure Functions solution optimized for GitHub metrics collection and processing. The architecture supports:

- Scalable data processing with elastic Function App scaling
- Secure data storage with managed identity authentication
- Comprehensive monitoring and logging capabilities
- Container-based deployment for consistent environments
