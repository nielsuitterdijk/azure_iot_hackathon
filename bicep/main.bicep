param location string = resourceGroup().location
param iotHubName string = 'iothubPOIU12'
param asaClusterName string = 'asaClusterPOIU12'
param asaJobName string = 'asaJobPOIU12'
param eventHubNamespace string = 'eventHubNamespacePOIU12'
param eventHubName string = 'eventHubPOIU12'

// IoT Hub
resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' = {
  name: iotHubName
  location: location
  sku: {
    name: 'S1' // Standard tier
    capacity: 1
  }
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 2
      }
    }
  }
}

// ASA Cluster
resource asaCluster 'Microsoft.StreamAnalytics/clusters@2020-03-01' = {
  name: asaClusterName
  location: location
  tags: {}
  sku: {
    capacity: 36
    name: 'Default'
  }
  properties: {}
}

// ASA Job
resource asaJob 'Microsoft.StreamAnalytics/streamingjobs@2021-10-01-preview' = {
  name: asaJobName
  location: location
  sku: {
    capacity: 36
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    cluster: {
      id: asaCluster.id
    }
    sku: {
      capacity: 36
      name: 'Standard'
    }
    eventsOutOfOrderPolicy: 'Adjust'
    outputErrorPolicy: 'Drop'
    eventsOutOfOrderMaxDelayInSeconds: 5
    eventsLateArrivalMaxDelayInSeconds: 16
    compatibilityLevel: '1.2'
    inputs: [
      {
        name: 'IoTHubInput'
        properties: {
          serialization: {
            type: 'Json'
            properties: {
              encoding: 'UTF8'
              format: 'LineSeparated'
            }
          }
          type: 'Stream'
          datasource: {
            type: 'Microsoft.Devices/IotHubs'
            properties: {
              iotHubNamespace: iotHub.name
              endpoint: 'messages/events'
              consumerGroupName: '$Default'
              authenticationMode: 'ManagedIdentity'
            }
          }
        }
      }
    ]
    outputs: [
      {
        name: 'EventHubOutput'
        properties: {
          datasource: {
            type: 'Microsoft.ServiceBus/EventHub'
            properties: {
              serviceBusNamespace: eventHubNamespace
              eventHubName: eventHubName
              sharedAccessPolicyName: 'RootManageSharedAccessKey'
              sharedAccessPolicyKey: 'policykey'
            }
          }
          serialization: {
            type: 'Json'
            properties: {
              encoding: 'UTF8'
              format: 'LineSeparated'
            }
          }
        }
      }
    ]
    transformation: {
      name: 'Transformation'
      properties: {
        streamingUnits: 1
        query: 'SELECT * INTO EventHubOutput FROM IoTHubInput'
      }
    }
  }
}

// Event Hubs Namespace
resource eventHubsNamespace 'Microsoft.EventHub/namespaces@2023-01-01-preview' = {
  name: eventHubNamespace
  location: location
  sku: {
    name: 'Standard'
  }
}

// Event Hub
resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  parent: eventHubsNamespace
  name: eventHubName
  properties: {
    partitionCount: 2
    messageRetentionInDays: 1
  }
}
