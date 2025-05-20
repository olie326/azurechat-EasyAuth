param disableLocalAuth bool

param searchServiceName string
param formRecognizerName string

param cognitiveServicesUserRoleId string
param searchServiceContributorRoleId string
param searchIndexDataContributorRoleId string
param targetUserPrincipal string

resource searchService 'Microsoft.Search/searchServices@2020-08-01' existing = {
  name: searchServiceName
}

resource formRecognizer 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: formRecognizerName
}

resource cognitiveServicesUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (disableLocalAuth) {
  name: guid(formRecognizer.id, cognitiveServicesUserRoleId, 'role-assignment-cognitiveServices')
  scope: resourceGroup()
  properties: {
    principalId: targetUserPrincipal
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)
  }
}

resource searchServiceContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (disableLocalAuth) {
  name: guid(searchService.id, searchServiceContributorRoleId, 'role-assignment-searchService')
  scope: searchService
  properties: {
    principalId: targetUserPrincipal
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchServiceContributorRoleId)
  }
}

resource searchServiceIndexDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (disableLocalAuth) {
  name: guid(searchService.id, searchIndexDataContributorRoleId, 'role-assignment-searchService')
  scope: searchService
  properties: {
    principalId: targetUserPrincipal
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      searchIndexDataContributorRoleId
    )
  }
}
