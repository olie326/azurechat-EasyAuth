param azureOpenAIName string
param targetUserPrincipal string
param cognitiveServicesContributorRoleId string
param cognitiveServicesOpenAIContributorRoleId string
param disableLocalAuth bool

resource azureopenai 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: azureOpenAIName
  scope: resourceGroup()
}

resource cognitiveServicesRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (disableLocalAuth) {
  name: guid(azureOpenAIName, cognitiveServicesContributorRoleId, 'role-assignment-cognitiveServices')
  scope: resourceGroup()
  properties: {
    principalId: targetUserPrincipal
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      cognitiveServicesContributorRoleId
    )
  }
}

resource cognitiveServicesOpenAIContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (disableLocalAuth) {
  name: guid(azureOpenAIName, cognitiveServicesOpenAIContributorRoleId, 'role-assignment-cognitiveServices')
  scope: azureopenai
  properties: {
    principalId: targetUserPrincipal
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      cognitiveServicesOpenAIContributorRoleId
    )
  }
}
