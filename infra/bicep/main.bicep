targetScope = 'subscription'

@minLength(2)
@maxLength(32)
@description('Name of the the azd environment.')
param environmentName string

@minLength(2)
@description('Primary location for all resources.')
param location string

@description('Name of the the resource group. Default: rg-{environmentName}')
param resourceGroupName string = ''

@description('Name of the the new containerapp environment. Default: aca-env-{environmentName}')
param managedEnvironmentName string = ''

@description('Name of the Azure Container Registry. Default: cr<uniqString>')
param acrName string = ''

@description('Name of the Open AI name, Default: openai-{environmentName}')
param openAiName string = ''

param utcValue string = utcNow()

var placeholderImage = 'azurespringapps/default-banner:latest'

var abbrs = loadJsonContent('./abbreviations.json')
var tags = {
  'azd-env-name': environmentName
  'utc-time': utcValue
}

@description('Organize resources in a resource group')
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

@description('Create user assigned managed identity for petclinic apps')
// apps will use this managed identity to connect MySQL, openAI etc
module umiApps 'modules/shared/userAssignedIdentity.bicep' = {
  name: 'umi-apps'
  scope: rg
  params: {
    name: 'umi-apps-${environmentName}'
  }
}


@description('Prepare Azure Container Registry for the images with UMI for AcrPull & AcrPush')
module acr 'modules/acr/acr.bicep' = {
  name: 'acr-${environmentName}'
  scope: rg
  params: {
    name: !empty(acrName) ? acrName : '${abbrs.containerRegistryRegistries}${uniqueString(rg.id)}'
    tags: tags
  }
}

@description('Import place holder image to new container registry')
module importImage 'modules/acr/importImage.bicep' = {
  name: 'import-image'
  scope: rg
  params: {
    acrName: acr.outputs.name
    source: 'mcr.microsoft.com/azurespringapps/default-banner:distroless-2024022107-66ea1a62-87936983'
    image: 'azurespringapps/default-banner:latest'
    umiAcrContributorId : acr.outputs.umiAcrContributorId
  }
}

var acrLoginServer = acr.outputs.loginServer

@description('Prepare Open AI instance')
module openai 'modules/ai/openai.bicep' = {
  name: 'openai-${environmentName}'
  scope: rg
  params: {
    accountName: !empty(openAiName) ? openAiName : 'openai-${environmentName}'
    appPrincipalId: umiApps.outputs.principalId
    tags: tags
  }
}

@description('Create Azure Container Apps environment')
module managedEnvironment 'modules/containerapps/aca-environment.bicep' = {
  name: 'managedEnvironment-${environmentName}'
  scope: rg
  params: {
    name: !empty(managedEnvironmentName) ? managedEnvironmentName : 'aca-env-${environmentName}'
    location: location
    userAssignedIdentities: {
      '${acr.outputs.umiAcrPullId}': {}
      '${umiApps.outputs.id}': {}
    }
    tags: tags
  }
}

@description('Create Azure Container Apps for the petclinic langchain4j project')
module petclinicApp 'modules/containerapps/containerapp.bicep' = {
  name: 'petclinic-${environmentName}'
  scope: rg
  params: {
    containerAppsEnvironmentName: managedEnvironment.outputs.containerAppsEnvironmentName
    name: 'petclinic-langchain4j'
    acrName: acrLoginServer
    acrIdentityId: acr.outputs.umiAcrPullId
    imageName: placeholderImage
    umiAppsIdentityId: umiApps.outputs.id
    external: true
    targetPort: 8080
    isJava: true
    env: [
      {
        name: 'LANGCHAIN4J_AZURE_OPEN_AI_CHAT_MODEL_ENDPOINT'
        value: openai.outputs.endpoint
      }
      {
        name: 'LANGCHAIN4J_AZURE_OPEN_AI_CHAT_MODEL_CLIENT_ID'
        value: umiApps.outputs.clientId
      }
    ]
    containerCpuCoreCount: '2'
    containerMemory: '4Gi'
  }
}

output subscriptionId string = subscription().subscriptionId
output resourceGroupName string = rg.name

output acrLoginServer string = acrLoginServer

output azdProvisionTimestamp string = 'azd-${environmentName}-${utcValue}'
