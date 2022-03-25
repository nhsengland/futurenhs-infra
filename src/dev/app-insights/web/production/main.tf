resource "azurerm_application_insights" "web" {
  name                                    = "appi-${var.product_name}-${var.environment}-${var.location}-web"
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

resource "azurerm_application_insights_web_test" "web-availability-test" {
  name                    = "appiwt-${var.product_name}-${var.environment}-${var.location}-web"
  description             = "Http ping test hitting the health check endpoint of the web server using the external domain"
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.web.id
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
<WebTest Name="APIAvailabilityWebTest" Id="8B1F907A-3829-4F29-835B-8C47BD8FD3CC" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="0" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">
  <Items>
    <Request Method="GET" Guid="0b9c88d1-ddb6-428f-9832-f315eb4282db" Version="1.1" Url="${var.application_fqdn}/gateway/web/health-check" ThinkTime="0" Timeout="300" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
  </Items>
</WebTest>
XML
}