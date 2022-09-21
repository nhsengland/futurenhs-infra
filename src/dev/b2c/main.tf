resource "azurerm_aadb2c_directory" "tenant" {
  country_code            = "GB"
  data_residency_location = "Europe"
  display_name            = "B2C-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}"
  domain_name             = "${var.domain_name}.onmicrosoft.com"
  resource_group_name     = var.resource_group_name
  sku_name                = "PremiumP1"
}

output "tenant_id" {
  value = azurerm_aadb2c_directory.tenant.tenant_id
}