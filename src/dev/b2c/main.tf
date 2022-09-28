
 ## resource "azurerm_aadb2c_directory" "tenant" {
 ##  country_code            = "GB"
 ##   data_residency_location = "Europe"
 ##   display_name            = "B2C-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}"
 ##   domain_name             = "${var.domain_name}.onmicrosoft.com"
 ##   resource_group_name     = var.resource_group_name
 ##   sku_name                = "PremiumP1"
 ## }

 ## module "tenant" {
 ##   source        = "./tenant"
 ##   tenant_id           = azurerm_aadb2c_directory.tenant.tenant_id
 ##   tenant_domain_name  = azurerm_aadb2c_directory.tenant.domain_name
 ##   application_fqdn    = var.application_fqdn
 ##   application_name    = var.application_name
 ## }


 ## output "tenant_id" {
 ##   value = azurerm_aadb2c_directory.tenant.tenant_id
 ## }