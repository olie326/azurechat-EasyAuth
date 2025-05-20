param name string = 'azurechat-demo'
param resourceToken string

param enableOpenAI bool
param enableDalle bool = false
param enableAzureAI bool

param openai_api_version string

param openAiLocation string
param openAiSkuName string
param chatGptDeploymentCapacity int
param chatGptDeploymentName string
param chatGptModelName string
param chatGptModelVersion string
param embeddingDeploymentName string
param embeddingDeploymentCapacity int
param embeddingModelName string

param dalleLocation string
param dalleDeploymentCapacity int
param dalleDeploymentName string
param dalleModelName string
param dalleApiVersion string

param speechServiceSkuName string = 'S0'

param formRecognizerSkuName string = 'S0'

param searchServiceSkuName string = 'standard'
param searchServiceIndexName string = 'azure-chat'

param storageServiceSku object
param storageServiceImageContainerName string

param location string = resourceGroup().location

param disableLocalAuth bool
param usePrivateEndpoints bool = false

@secure()
param nextAuthHash string = uniqueString(newGuid())

param tags object = {}

param privateEndpointVNetPrefix string = '192.168.0.0/16'
param privateEndpointSubnetAddressPrefix string = '192.168.0.0/24'
param appServiceBackendSubnetAddressPrefix string = '192.168.1.0/24'

var openai_name = toLower('${name}-aillm-${resourceToken}')
var openai_dalle_name = toLower('${name}-aidalle-${resourceToken}')

var form_recognizer_name = toLower('${name}-form-${resourceToken}')
var speech_service_name = toLower('${name}-speech-${resourceToken}')
var cosmos_name = toLower('${name}-cosmos-${resourceToken}')
var search_name = toLower('${name}search${resourceToken}')
var webapp_name = toLower('${name}-webapp-${resourceToken}')
var appservice_name = toLower('${name}-app-${resourceToken}')
// storage name must be < 24 chars, alphanumeric only. 'sto' is 3 and resourceToken is 13
var clean_name = replace(replace(name, '-', ''), '_', '')
var storage_prefix = take(clean_name, 8)
var storage_name = toLower('${storage_prefix}sto${resourceToken}')
// keyvault name must be less than 24 chars - token is 13, 'kv' is 2
var kv_prefix = take(clean_name, 7)
var keyVaultName = toLower('${kv_prefix}kv${resourceToken}')
var la_workspace_name = toLower('${name}-la-${resourceToken}')
var diagnostic_setting_name = 'AppServiceConsoleLogs'

var keyVaultSecretsOfficerRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
)

var validStorageServiceImageContainerName = toLower(replace(storageServiceImageContainerName, '-', ''))

var databaseName = 'chat'
var historyContainerName = 'history'
var configContainerName = 'config'

module privateEndpoints 'private_endpoints_core.bicep' = if (usePrivateEndpoints) {
  name: 'private-endpoints'
  params: {
    location: location
    name: name
    resourceToken: resourceToken
    tags: tags
    cosmos_id: cosmosDbAccount.id
    openai_id: enableOpenAI ? openai.outputs.azureopenai_id : ''
    form_recognizer_id: enableAzureAI ? ai.outputs.formRecognizer_id : ''
    search_service_id: enableAzureAI ? ai.outputs.searchService_id : ''
    openai_dalle_id: enableDalle ? dalle.outputs.azureopenai_dalle_id : ''
    storage_id: storage.id
    keyVault_id: kv.id
    privateEndpointVNetPrefix: privateEndpointVNetPrefix
    privateEndpointSubnetAddressPrefix: privateEndpointSubnetAddressPrefix
    appServiceBackendSubnetAddressPrefix: appServiceBackendSubnetAddressPrefix
  }
}

module openai 'modules/openai.bicep' = if (enableOpenAI) {
  name: 'openai'
  params: {
    name: name
    resourceToken: resourceToken
    tags: tags
    openAiLocation: openAiLocation
    openAiSkuName: openAiSkuName
    chatGptDeploymentName: chatGptDeploymentName
    chatGptDeploymentCapacity: chatGptDeploymentCapacity
    chatGptModelName: chatGptModelName
    chatGptModelVersion: chatGptModelVersion
    embeddingDeploymentName: embeddingDeploymentName
    embeddingDeploymentCapacity: embeddingDeploymentCapacity
    embeddingModelName: embeddingModelName
    keyVaultName: keyVaultName
    disableLocalAuth: disableLocalAuth
  }
}

module dalle 'modules/dalle.bicep' = if (enableDalle) {
  name: 'dalle'
  params: {
    name: name
    resourceToken: resourceToken
    tags: tags
    dalleDeploymentName: dalleDeploymentName
    dalleDeploymentCapacity: dalleDeploymentCapacity
    dalleModelName: dalleModelName
    dalleLocation: dalleLocation
    keyVaultName: keyVaultName
    openAiSkuName: openAiSkuName
    disableLocalAuth: disableLocalAuth
  }
}

module ai 'modules/azure_ai.bicep' = if (enableAzureAI) {
  name: 'ai'
  params: {
    tags: tags
    location: location
    formRecognizerSkuName: formRecognizerSkuName
    searchServiceSkuName: searchServiceSkuName
    disableLocalAuth: disableLocalAuth
    form_recognizer_name: form_recognizer_name
    keyVaultName: keyVaultName
    search_name: search_name
    speech_service_name: speech_service_name
    speechServiceSkuName: speechServiceSkuName
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appservice_name
  location: location
  tags: tags
  properties: {
    reserved: true
  }
  sku: {
    name: 'B3'
    tier: 'Basic'
    capacity: 1
  }
  kind: 'linux'
}

var appSettingsOpenAICommon = enableOpenAI
  ? [
      {
        name: 'AZURE_OPENAI_API_INSTANCE_NAME'
        value: openai_name
      }
      {
        name: 'AZURE_OPENAI_API_DEPLOYMENT_NAME'
        value: chatGptDeploymentName
      }
      {
        name: 'AZURE_OPENAI_API_EMBEDDINGS_DEPLOYMENT_NAME'
        value: embeddingDeploymentName
      }
      {
        name: 'AZURE_OPENAI_API_VERSION'
        value: openai_api_version
      }
    ]
  : []

var appSettingsDalleCommon = enableDalle
  ? [
      {
        name: 'AZURE_OPENAI_DALLE_API_INSTANCE_NAME'
        value: openai_dalle_name
      }
      {
        name: 'AZURE_OPENAI_DALLE_API_DEPLOYMENT_NAME'
        value: dalleDeploymentName
      }
      {
        name: 'AZURE_OPENAI_DALLE_API_VERSION'
        value: dalleApiVersion
      }
    ]
  : []

var appSettingsAICommon = enableAzureAI
  ? [
      {
        name: 'AZURE_SEARCH_NAME'
        value: search_name
      }
      {
        name: 'AZURE_SEARCH_INDEX_NAME'
        value: searchServiceIndexName
      }
    ]
  : []

var appSettingsCommon = [
  {
    name: 'USE_MANAGED_IDENTITIES'
    value: disableLocalAuth
  }
  {
    name: 'AZURE_KEY_VAULT_NAME'
    value: keyVaultName
  }
  {
    name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
    value: 'true'
  }
  {
    name: 'NEXTAUTH_SECRET'
    value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${kv::NEXTAUTH_SECRET.name})'
  }
  {
    name: 'NEXTAUTH_URL'
    value: 'https://${webapp_name}.azurewebsites.net'
  }
  {
    name: 'AZURE_COSMOSDB_URI'
    value: cosmosDbAccount.properties.documentEndpoint
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_NAME'
    value: storage_name
  }
]

var appSettingsCommonAll = concat(
  appSettingsCommon,
  appSettingsOpenAICommon,
  appSettingsDalleCommon,
  appSettingsAICommon
)
var openaiSecretName = enableOpenAI ? openai.outputs.openaiSecretName : ''
var openaiDalleSecretName = enableDalle ? dalle.outputs.openaiDalleSecretName : ''
var searchServiceSecretName = enableAzureAI ? ai.outputs.searchServiceSecretName : ''
var formRecognizerSecretName = enableAzureAI ? ai.outputs.formRecognizerSecretName : ''

// var openaiSecretName = ''
// var openaiDalleSecretName = ''
// var searchServiceSecretName = ''
// var formRecognizerSecretName = ''
var appSettingsWithLocalAuthOpenAI = enableOpenAI && !disableLocalAuth
  ? [
      {
        name: 'AZURE_OPENAI_API_KEY'
        value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${openaiSecretName})'
      }
    ]
  : []

var appSettingsWithLocalAuthDalle = enableDalle && !disableLocalAuth
  ? [
      {
        name: 'AZURE_OPENAI_DALLE_API_KEY'
        value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${openaiDalleSecretName})'
      }
    ]
  : []

var appSettingsWithLocalAuthAI = enableAzureAI && !disableLocalAuth
  ? [
      {
        name: 'AZURE_SEARCH_API_KEY'
        value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${searchServiceSecretName})'
      }
      {
        name: 'AZURE_DOCUMENT_INTELLIGENCE_KEY'
        value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${formRecognizerSecretName})'
      }
    ]
  : []

var appSettingsWithLocalAuth = disableLocalAuth
  ? []
  : [
      {
        name: 'AZURE_COSMOSDB_KEY'
        value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${kv::AZURE_COSMOSDB_KEY.name})'
      }
      {
        name: 'AZURE_STORAGE_ACCOUNT_KEY'
        value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${kv::AZURE_STORAGE_ACCOUNT_KEY.name})'
      }
    ]

var appSettingsWithLocalAuthAll = concat(
  appSettingsWithLocalAuth,
  appSettingsWithLocalAuthOpenAI,
  appSettingsWithLocalAuthDalle,
  appSettingsWithLocalAuthAI
)

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webapp_name
  location: location
  tags: union(tags, { 'azd-service-name': 'frontend' })
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: usePrivateEndpoints ? privateEndpoints.outputs.appServiceSubnetId : null
    vnetRouteAllEnabled: usePrivateEndpoints ? false : null
    siteConfig: {
      linuxFxVersion: 'NODE|22-lts'
      alwaysOn: true
      appCommandLine: 'next start'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: concat(appSettingsCommonAll, appSettingsWithLocalAuthAll)
    }
  }
  identity: { type: 'SystemAssigned' }

  resource configLogs 'config' = {
    name: 'logs'
    properties: {
      applicationLogs: { fileSystem: { level: 'Verbose' } }
      detailedErrorMessages: { enabled: true }
      failedRequestsTracing: { enabled: true }
      httpLogs: { fileSystem: { enabled: true, retentionInDays: 1, retentionInMb: 35 } }
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: la_workspace_name
  location: location
}

resource webDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnostic_setting_name
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
    ]
    metrics: []
  }
}

resource kvFunctionAppPermissions 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(kv.id, webApp.name, keyVaultSecretsOfficerRole)
  scope: kv
  properties: {
    principalId: targetUserPrincipal
    principalType: 'ServicePrincipal'
    roleDefinitionId: keyVaultSecretsOfficerRole
  }
}

resource kv 'Microsoft.KeyVault/vaults@2024-12-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: usePrivateEndpoints ? 'Disabled' : 'Enabled'
  }

  resource NEXTAUTH_SECRET 'secrets' = {
    name: 'NEXTAUTH-SECRET'
    properties: {
      contentType: 'text/plain'
      value: nextAuthHash
    }
  }

  resource AZURE_COSMOSDB_KEY 'secrets' = if (!disableLocalAuth) {
    name: 'AZURE-COSMOSDB-KEY'
    properties: {
      contentType: 'text/plain'
      value: cosmosDbAccount.listKeys().secondaryMasterKey
    }
  }

  resource AZURE_STORAGE_ACCOUNT_KEY 'secrets' = if (!disableLocalAuth) {
    name: 'AZURE-STORAGE-ACCOUNT-KEY'
    properties: {
      contentType: 'text/plain'
      value: storage.listKeys().keys[0].value
    }
  }
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmos_name
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    disableLocalAuth: disableLocalAuth
    publicNetworkAccess: usePrivateEndpoints ? 'Disabled' : 'Enabled'
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    disableKeyBasedMetadataWriteAccess: true
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  name: databaseName
  parent: cosmosDbAccount
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource historyContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  name: historyContainerName
  parent: database
  properties: {
    resource: {
      id: historyContainerName
      partitionKey: {
        paths: [
          '/userId'
        ]
        kind: 'Hash'
      }
    }
  }
}

resource configContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  name: configContainerName
  parent: database
  properties: {
    resource: {
      id: configContainerName
      partitionKey: {
        paths: [
          '/userId'
        ]
        kind: 'Hash'
      }
    }
  }
}

// TODO: define good default Sku and settings for storage account
resource storage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storage_name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: storageServiceSku
  properties: {
    allowSharedKeyAccess: !disableLocalAuth
    publicNetworkAccess: usePrivateEndpoints ? 'Disabled' : 'Enabled'
    minimumTlsVersion: 'TLS1_2'
  }

  resource blobServices 'blobServices' = {
    name: 'default'
    resource container 'containers' = {
      name: validStorageServiceImageContainerName
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

//RBAC Roles for managed identity authentication

var cosmosDbContributorRoleId = '5bd9cd88-fe45-4216-938b-f97437e15450' // Replace with actual role ID for Cosmos DB.
var cosmosDbOperatorRoleId = '230815da-be43-4aae-9cb4-875f7bd000aa'
var cognitiveServicesContributorRoleId = '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68' // Replace with actual role ID for Cognitive Services.
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Replace with actual role ID for Blob Data Contributor.
var searchServiceContributorRoleId = '7ca78c08-252a-4471-8644-bb5ff32d4ba0' // Replace with actual role ID for Azure Search.
var cognitiveServicesOpenAIContributorRoleId = 'a001fd3d-188f-4b5d-821b-7da978bf7442'
var searchIndexDataContributorRoleId = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'

var targetUserPrincipal = webApp.identity.principalId
// These are only deployed if local authentication has been disabled in the parameters

module openaiRoles 'modules/openai_roles.bicep' = if (enableOpenAI && disableLocalAuth) {
  name: 'openai-roles'
  params: {
    azureOpenAIName: openai.outputs.openai_name
    targetUserPrincipal: targetUserPrincipal
    cognitiveServicesContributorRoleId: cognitiveServicesContributorRoleId
    cognitiveServicesOpenAIContributorRoleId: cognitiveServicesOpenAIContributorRoleId
    disableLocalAuth: disableLocalAuth
  }
}

module azureAIRoles 'modules/azure_ai_roles.bicep' = if (enableAzureAI && disableLocalAuth) {
  name: 'azure-ai-roles'
  params: {
    disableLocalAuth: disableLocalAuth
    targetUserPrincipal: webApp.identity.principalId
    cognitiveServicesUserRoleId: cognitiveServicesUserRoleId
    formRecognizerName: form_recognizer_name
    searchIndexDataContributorRoleId: searchIndexDataContributorRoleId
    searchServiceContributorRoleId: searchServiceContributorRoleId
    searchServiceName: search_name
  }
}

resource cosmosDbRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (disableLocalAuth) {
  name: guid(cosmosDbAccount.id, cosmosDbContributorRoleId, 'role-assignment-cosmosDb')
  scope: cosmosDbAccount
  properties: {
    principalId: targetUserPrincipal
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cosmosDbContributorRoleId)
  }
}

resource cosmosDbRoleAssignmentOperator 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (disableLocalAuth) {
  name: guid(cosmosDbAccount.id, cosmosDbOperatorRoleId, 'role-assignment-cosmosDb')
  scope: cosmosDbAccount
  properties: {
    principalId: targetUserPrincipal
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cosmosDbOperatorRoleId)
  }
}

resource storageBlobDataContributorRole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (disableLocalAuth) {
  name: guid(storage.id, storageBlobDataContributorRoleId, 'role-assignment-storage')
  scope: storage
  properties: {
    principalId: targetUserPrincipal
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageBlobDataContributorRoleId
    )
  }
}

//Special case for cosmosdb

@description('Name of the role definition.')
param roleDefinitionName string = 'Azure Cosmos DB for NoSQL Data Plane Owner'

resource definition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2024-05-15' = if (disableLocalAuth) {
  name: guid(cosmosDbAccount.id, roleDefinitionName)
  parent: cosmosDbAccount
  properties: {
    roleName: roleDefinitionName
    type: 'CustomRole'
    assignableScopes: [
      cosmosDbAccount.id
    ]
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
        ]
      }
    ]
  }
}

resource assignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = if (disableLocalAuth) {
  name: guid(definition.id, webApp.name, cosmosDbAccount.id)
  parent: cosmosDbAccount
  properties: {
    principalId: targetUserPrincipal
    roleDefinitionId: definition.id
    scope: cosmosDbAccount.id
  }
}

output url string = 'https://${webApp.properties.defaultHostName}'

output webapp_name string = webapp_name
output cosmos_name string = cosmos_name
output cosmos_endpoint string = cosmosDbAccount.properties.documentEndpoint
output database_name string = databaseName
output history_container_name string = historyContainerName
output config_container_name string = configContainerName
// output cosmos_endpoint string = ''
// output database_name string = ''
// output history_container_name string = ''
// output config_container_name string = ''

output search_name string = search_name
output form_recognizer_name string = form_recognizer_name
// output search_name string = ''
// output form_recognizer_name string = ''
output storage_name string = storage_name
// output storage_name string = ''
output key_vault_name string = keyVaultName
output openai_name string = enableOpenAI ? openai.outputs.openai_name : ''
output openai_dalle_name string = enableDalle ? dalle.outputs.openai_dalle_name : ''
// output openai_name string = ''
// output openai_dalle_name string = ''
