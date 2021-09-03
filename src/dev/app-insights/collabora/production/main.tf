resource "azurerm_application_insights" "collabora" {
  name                                    = "appi-${var.product_name}-${var.environment}-${var.location}-collabora"
  location                                = var.location
  resource_group_name                     = var.resource_group_name
  application_type                        = "web"

  # TODO - change these settings for a production environment

  daily_data_cap_in_gb                    = 1
  sampling_percentage                     = 100

  daily_data_cap_notifications_disabled   = false
  retention_in_days                       = 120
  disable_ip_masking                      = false
}

# https://docs.microsoft.com/en-gb/azure/azure-monitor/app/monitor-web-app-availability

resource "azurerm_application_insights_web_test" "collabora-availability-test" {
  name                    = "appiwt-${var.product_name}-${var.environment}-${var.location}-collabora"
  description             = "Http ping test hitting the health check endpoint of the file server using the external domain"
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.collabora.id
  kind                    = "ping" 
  frequency               = 300
  timeout                 = 60
  enabled                 = true
  geo_locations           = ["emea-ru-msa-edge", "emea-se-sto-edge"] # UK South and UK West

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  configuration = <<XML
<WebTest Name="FilesAvailabilityWebTest" Id="A0F2BD5F-6FA5-4510-9E17-E24DF44EECC2" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="0" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">
  <Items>
    <Request Method="GET" Guid="9f8d1a50-a8d5-4600-b6a0-e56de6d857b7" Version="1.1" Url="${var.application_fqdn}/gateway/wopi/client/" ThinkTime="0" Timeout="300" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
  </Items>
</WebTest>
XML
}