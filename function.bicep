@description('Name that will be used to build associated artifacts')
param keyvaultName string

@description('Location for all resources.')
param location string

@description('App insights connection string')
param appInsightsConnectionString string

@description('Storage account secret name')
param storageSecretName string

@description('Storage account name')
param storageAccountName string

@description('Trigger connection string')
param triggerStorageQueueUri string = ''

@description('Run from package')
param runFromPackage bool = true

@description('Function App name')
param functionAppName string

@description('AdditionalAppSettings')
param additionalAppSettings array = []

@description('User Identity Name')
param userIdentityId string

@description('Database Connection String')
param databaseConnectionString string = ''

@description('Managed Identity Client Id')
param managedIdentityClientId string

@description('Enable CORS')
param enableCors bool = false

var functionAppServicePlanName = functionAppName

resource functionPlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: functionAppServicePlanName
  location: location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
  }
  properties: {}
}

var baseAppsettings = union([
    {
      name: 'FUNCTIONS_WORKER_RUNTIME'
      value: 'dotnet'
    }
    {
      name: 'FUNCTIONS_EXTENSION_VERSION'
      value: '~4'
    }
    {
      name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE'
      value: 'true'
    }
    {
      name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
      value: appInsightsConnectionString
    }
    {
      name: 'AzureWebJobsStorage__accountName'
      value: storageAccountName
    }
    {
      name: 'AzureWebJobsStorage__credential'
      value: 'managedidentity'
    }
    {
      name: 'AzureWebJobsStorage__clientId'
      value: managedIdentityClientId
    }
    // annoying bug on first deploy (edit portal template and put in proper connectionstring)
    {
      name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
      value: '@Microsoft.KeyVault(VaultName=${keyvaultName};SecretName=${storageSecretName})'
    }
    {
      name: 'WEBSITE_CONTENTSHARE'
      value: toLower(functionAppName)
    }
  ], additionalAppSettings)

var runFromPackageSetting = [
  {
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: '1'
  }
]

var triggerConnectionSetting = [
  {
    name: 'ConnectionString__queueServiceUri'
    value: triggerStorageQueueUri
  }
  {
    name: 'ConnectionString__credential'
    value: 'managedidentity'
  }
  {
    name: 'ConnectionString__clientId'
    value: managedIdentityClientId
  }
]

var databaseConnectionSetting = [
  {
    name: 'DatabaseConnectionString'
    value: databaseConnectionString
  }
]

var triggerAndBaseSettings = triggerStorageQueueUri == '' ? baseAppsettings : union(baseAppsettings, triggerConnectionSetting)
var databaseTriggerAndBaseSettings = databaseConnectionSetting == '' ? triggerAndBaseSettings : union(triggerAndBaseSettings, databaseConnectionSetting)
var allAppSettings = runFromPackage ? union(databaseTriggerAndBaseSettings, runFromPackageSetting) : databaseTriggerAndBaseSettings

var baseSiteConfig = {
  appSettings: allAppSettings
}

var corsConfig = {
  cors: {
    allowedOrigins: [
      'https://musicvideobuilder.com'
    ]
  }
}

var siteConfig = enableCors ? union(baseSiteConfig, corsConfig) : baseSiteConfig

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: functionPlan.id
    siteConfig: siteConfig
    httpsOnly: true
    keyVaultReferenceIdentity: userIdentityId
  }
}
