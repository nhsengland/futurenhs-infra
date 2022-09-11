
data "azuread_application_published_app_ids" "well_known" {}
resource "azuread_service_principal" "msgraph" {

use_existing   = true
}


resource "azuread_application" "graph_worker" {
display_name     = var.application_name
sign_in_audience = "AzureADMyOrg"


web {
redirect_uris = ["${var.application_fqdn}/api/auth/callback/azure-ad-b2c/"]
}


required_resource_access {
resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph


resource_access {
  id   = azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
  type = "Role"
}

}
}

resource "azuread_service_principal" "graph_worker" {
application_id      = azuread_application.graph_worker.application_id
}

resource "azuread_app_role_assignment" "graph_worker" {
app_role_id         = azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
principal_object_id = azuread_service_principal.graph_worker.object_id
resource_object_id  = azuread_service_principal.msgraph.object_id
}