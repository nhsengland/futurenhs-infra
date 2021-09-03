# We need to create our own managed service identity for the gateway as it doesn't support SystemAssigned

resource "azurerm_user_assigned_identity" "app_gateway" {
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  name                                           = "agwmsi-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-default"
}