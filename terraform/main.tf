provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = "bicep-asa-test"
}

resource "azurerm_iothub" "iothub" {
  name                = "iothubPOIU12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku {
    name     = "S1"
    capacity = 1
  }
}

resource "azurerm_eventhub_namespace" "eventhub_namespace" {
  name                = "eventHubNamespacePOIU12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Standard"
}

resource "azurerm_eventhub" "eventhub" {
  name                = "eventhubpoiu12"
  namespace_name      = azurerm_eventhub_namespace.eventhub_namespace.name
  resource_group_name = data.azurerm_resource_group.rg.name
  message_retention   = 5
  partition_count     = 2
}

resource "azurerm_stream_analytics_cluster" "asa_cluster" {
  name                = "asaClusterPOIU12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  streaming_capacity  = 36
}
resource "azurerm_stream_analytics_job" "asa_job" {
  name                                     = "forwardJob"
  resource_group_name                      = data.azurerm_resource_group.rg.name
  location                                 = data.azurerm_resource_group.rg.location
  compatibility_level                      = "1.2"
  data_locale                              = "en-GB"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy               = "Adjust"
  output_error_policy                      = "Drop"
  streaming_units                          = 3
  stream_analytics_cluster_id              = azurerm_stream_analytics_cluster.asa_cluster.id

  identity {
    type = "SystemAssigned"
  }

  transformation_query = <<QUERY
    SELECT *
    INTO EventHubOutput
    FROM IoTHubInput
QUERY

}

resource "azurerm_stream_analytics_stream_input_iothub" "iot_input" {
  name                         = var.asaJobInputName
  stream_analytics_job_name    = azurerm_stream_analytics_job.asa_job.name
  resource_group_name          = azurerm_stream_analytics_job.asa_job.resource_group_name
  endpoint                     = "messages/events"
  eventhub_consumer_group_name = "$Default"
  iothub_namespace             = azurerm_iothub.iothub.name
  shared_access_policy_key     = azurerm_iothub.iothub.shared_access_policy[0].primary_key
  shared_access_policy_name    = "iothubowner"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}
resource "azurerm_stream_analytics_output_eventhub" "eventhub_output" {
  name                      = var.asaJobOutputName
  stream_analytics_job_name = azurerm_stream_analytics_job.asa_job.name
  resource_group_name       = azurerm_stream_analytics_job.asa_job.resource_group_name
  eventhub_name             = azurerm_eventhub.eventhub.name
  servicebus_namespace      = azurerm_eventhub_namespace.eventhub_namespace.name
  shared_access_policy_key  = azurerm_eventhub_namespace.eventhub_namespace.default_primary_key
  shared_access_policy_name = "RootManageSharedAccessKey"

  serialization {
    type = "Avro"
  }
}
