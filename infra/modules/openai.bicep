param name string = 'azurechat-demo'
param resourceToken string

param disableLocalAuth bool

param chatGptDeploymentCapacity int
param chatGptDeploymentName string
param chatGptModelName string
param chatGptModelVersion string
param embeddingDeploymentName string
param embeddingDeploymentCapacity int
param embeddingModelName string
param openAiLocation string
param openAiSkuName string

param tags object
param usePrivateEndpoints bool = false
param keyVaultName string

var openai_name = toLower('${name}-aillm-${resourceToken}')

var llmDeployments = [
  {
    name: chatGptDeploymentName
    model: {
      format: 'OpenAI'
      name: chatGptModelName
      version: chatGptModelVersion
    }
    sku: {
      name: 'GlobalStandard'
      capacity: chatGptDeploymentCapacity
    }
  }
  {
    name: embeddingDeploymentName
    model: {
      format: 'OpenAI'
      name: embeddingModelName
      version: '2'
    }
    capacity: embeddingDeploymentCapacity
  }
]

resource kv 'Microsoft.KeyVault/vaults@2024-12-01-preview' existing = {
  name: keyVaultName
}

resource AZURE_OPENAI_API_KEY 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = if (!disableLocalAuth) {
  parent: kv
  name: 'AZURE-OPENAI-API-KEY'
  properties: {
    contentType: 'text/plain'
    value: azureopenai.listKeys().key1
  }
}

resource azureopenai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openai_name
  location: openAiLocation
  tags: tags
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openai_name
    publicNetworkAccess: usePrivateEndpoints ? 'Disabled' : 'Enabled'
    disableLocalAuth: disableLocalAuth
  }
  sku: {
    name: openAiSkuName
  }
}

@batchSize(1)
resource llmdeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [
  for deployment in llmDeployments: {
    parent: azureopenai
    name: deployment.name
    properties: {
      model: deployment.model
      /*raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null*/
    }
    sku: contains(deployment, 'sku')
      ? deployment.sku
      : {
          name: 'Standard'
          capacity: deployment.capacity
        }
  }
]

output openai_name string = openai_name
output azureopenai_id string = azureopenai.id
output azureopenai_api_key_id string = AZURE_OPENAI_API_KEY.id
output openaiSecretName string = 'AZURE-OPENAI-API-KEY'
