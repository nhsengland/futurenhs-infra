resource "azurerm_container_registry" "container_registry" {
  name                = "cr${lower(var.product_name)}${lower(var.environment)}${lower(var.location)}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}