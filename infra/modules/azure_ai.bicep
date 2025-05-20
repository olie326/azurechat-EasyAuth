param disableLocalAuth bool
param keyVaultName string
param location string
param tags object
param usePrivateEndpoints bool = false
param formRecognizerSkuName string
param searchServiceSkuName string
param speechServiceSkuName string
param form_recognizer_name string
param search_name string
param speech_service_name string

resource kv 'Microsoft.KeyVault/vaults@2024-12-01-preview' existing = {
  name: keyVaultName
}

resource AZURE_DOCUMENT_INTELLIGENCE_KEY 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = if (!disableLocalAuth) {
  parent: kv
  name: 'AZURE-DOCUMENT-INTELLIGENCE-KEY'
  properties: {
    contentType: 'text/plain'
    value: formRecognizer.listKeys().key1
  }
}

resource AZURE_SPEECH_KEY 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: kv
  name: 'AZURE-SPEECH-KEY'
  properties: {
    contentType: 'text/plain'
    value: speechService.listKeys().key1
  }
}

resource AZURE_SEARCH_API_KEY 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = if (!disableLocalAuth) {
  parent: kv
  name: 'AZURE-SEARCH-API-KEY'
  properties: {
    contentType: 'text/plain'
    value: searchService.listAdminKeys().secondaryKey
  }
}

resource formRecognizer 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: form_recognizer_name
  location: location
  tags: tags
  kind: 'FormRecognizer'
  properties: {
    customSubDomainName: form_recognizer_name
    publicNetworkAccess: usePrivateEndpoints ? 'Disabled' : 'Enabled'
    disableLocalAuth: disableLocalAuth
  }
  sku: {
    name: formRecognizerSkuName
  }
}

resource searchService 'Microsoft.Search/searchServices@2022-09-01' = {
  name: search_name
  location: location
  tags: tags
  properties: {
    partitionCount: 1
    publicNetworkAccess: usePrivateEndpoints ? 'disabled' : 'enabled'
    replicaCount: 1
    disableLocalAuth: disableLocalAuth
  }
  sku: {
    name: searchServiceSkuName
  }
}

resource speechService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: speech_service_name
  location: location
  tags: tags
  kind: 'SpeechServices'
  properties: {
    customSubDomainName: speech_service_name
    // called from the browser so public endpoint is required
    publicNetworkAccess: 'Enabled'
    /* TODO: disableLocalAuth: disableLocalAuth*/
  }
  sku: {
    name: speechServiceSkuName
  }
}

output formRecognizer_id string = formRecognizer.id
output searchService_id string = searchService.id
output speechService_id string = speechService.id
output searchServiceSecretName string = 'AZURE_SEARCH_API_KEY'
output speechServiceSecretName string = 'AZURE_SPEECH_KEY'
output formRecognizerSecretName string = 'AZURE_DOCUMENT_INTELLIGENCE_KEY'
