@description('Name that will be used to build associated artifacts')
param resourceName string

@description('Location for all resources.')
param location string

var functionAppServicePlanName = '${resourceName}function'
var functionAppName = '${resourceName}function'
var keyvaultName = resourceName

resource functionPlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: functionAppServicePlanName
  location: location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: functionPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name:'AzureKeyVaultEndpoint'
          value:'https://${keyvaultName}.vault.azure.net/'
        }
      ]
      cors:{
        allowedOrigins: [
          '*'//CHANGE THIS
        ]
      }
    }
    httpsOnly: true
  }
}

// resource function 'Microsoft.Web/sites/functions@2020-12-01' = {
//   name: '${functionApp.name}/ImageUploaderFunction'
//   properties: {
//     config: {
//       disabled: false
//       bindings: [
//         {
//           name: 'req'
//           type: 'httpTrigger'
//           direction: 'in'
//           authLevel: 'function'
//           methods: [
//             'post'
//           ]
//         }
//         {
//           name: '$return'
//           type: 'http'
//           direction: 'out'
//         }
//       ]
//     }
//   }
// }
