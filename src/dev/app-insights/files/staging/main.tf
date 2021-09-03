# We have a separate instance of app insights for the staging slot so we can monitor release through azure monitor
# and rollback if anything goes wrong in the first N minutes.  Assuming all is ok, traffic can start to be routed to 
# staging and thereafter the slots swapped over

# Note that the release pipeline will also add some tests to the monitor and alerts that execute off the back of them

resource "azurerm_application_insights" "files_staging" {
  name                                    = "appi-${var.product_name}-${var.environment}-${var.location}-files-staging"
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