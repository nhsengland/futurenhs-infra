resource "azurerm_app_service_active_slot" "main" {
  resource_group_name               = var.resource_group_name
  app_service_name                  = "app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-001"
  app_service_slot_name             = "appslot-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-001"
}