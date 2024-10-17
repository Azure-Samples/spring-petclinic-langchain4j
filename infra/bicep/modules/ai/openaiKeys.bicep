targetScope = 'resourceGroup'

param keyvaultName string

param cogAccountName string

@description('save endpoint to kv')
module saveEndpoint '../security/keyvault-secret.bicep' = {
  name: 'save-endpoint-to-kv'
  params: {
    keyVaultName: keyvaultName
    name: 'langchain4j-azure-openai-chatmodel-endpoint'
    secretValue: account.properties.endpoint
  }
}

@description('save key to kv')
module saveKey '../security/keyvault-secret.bicep' = {
  name: 'save-key-to-kv'
  params: {
    keyVaultName: keyvaultName
    name: 'langchain4j-azure-openai-chatmodel-apikey'
    secretValue: account.listKeys().key1
  }
}

@description('save key to kv')
module saveDeploymentName '../security/keyvault-secret.bicep' = {
  name: 'save-deploymentname-to-kv'
  params: {
    keyVaultName: keyvaultName
    name: 'langchain4j-azure-openai-chatmodel-deploymentname'
    secretValue: 'gpt-4o'
  }
}

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: cogAccountName
}
