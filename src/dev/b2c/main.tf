
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

resource "azurerm_storage_blob" "b2c_html" {
  for_each               = fileset(path.module, "public/html/*")
  name                   = split("/", each.key)[2]
  storage_account_name   = var.storage_account_name
  storage_container_name = var.storage_container_name
  type                   = "Block"
  content_type           = "text/html"
  source_content = templatefile("${path.module}/${each.key}", {
    ENV      = var.environment
    HOME_URL = var.environment == "prod" ? "https://collaborate.future.nhs.uk" : "https://collaborate-${var.environment}.future.nhs.uk"
  })
}

resource "azurerm_storage_blob" "b2c_css" {
  for_each               = fileset(path.module, "public/css/*")
  name                   = split("/", each.key)[2]
  storage_account_name   = var.storage_account_name
  storage_container_name = var.storage_container_name
  type                   = "Block"
  content_type           = "text/css"
  source                 = "${path.module}/${each.key}"
}