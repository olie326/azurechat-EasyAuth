param name string = 'azurechat-demo'
param resourceToken string

param disableLocalAuth bool

param dalleLocation string
param dalleDeploymentCapacity int
param dalleDeploymentName string
param dalleModelName string

param tags object
param usePrivateEndpoints bool = false
param openAiSkuName string
param keyVaultName string

var openai_dalle_name = toLower('${name}-aidalle-${resourceToken}')

resource azureopenaidalle 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openai_dalle_name
  location: dalleLocation
  tags: tags
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openai_dalle_name
    publicNetworkAccess: usePrivateEndpoints ? 'Disabled' : 'Enabled'
    disableLocalAuth: disableLocalAuth
  }
  sku: {
    name: openAiSkuName
  }

  resource dalleDeployment 'deployments' = {
    name: dalleDeploymentName
    properties: {
      model: {
        format: 'OpenAI'
        name: dalleModelName
      }
    }
    sku: {
      name: 'Standard'
      capacity: dalleDeploymentCapacity
    }
  }
}

resource kv 'Microsoft.KeyVault/vaults@2024-12-01-preview' existing = {
  name: keyVaultName
}

resource AZURE_OPENAI_DALLE_API_KEY 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = if (!disableLocalAuth) {
  parent: kv
  name: 'AZURE-OPENAI-DALLE-API-KEY'
  properties: {
    contentType: 'text/plain'
    value: azureopenaidalle.listKeys().key1
  }
}

output openai_dalle_name string = openai_dalle_name
output azureopenai_dalle_id string = azureopenaidalle.id
output azureopenai_dalle_api_key_id string = AZURE_OPENAI_DALLE_API_KEY.id
output openaiDalleSecretName string = 'AZURE_OPENAI_DALLE_API_KEY'
