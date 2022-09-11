data "azuread_client_config" "current" {}

data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing = true
}


resource "azuread_application" "app-api" {
  display_name = var.application_name
  owners       = [data.azuread_client_config.current.object_id]
  

  api {
     oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access example on behalf of the signed-in user."
      admin_consent_display_name = "Access example"
      enabled                    = true
      id                         = "96183846-204b-4b43-82e1-5d2222eb4b9b"
      type                       = "User"
      user_consent_description   = "Allow the application to access example on your behalf."
      user_consent_display_name  = "Access example"
      value                      = "user_impersonation"
    }
  }

  app_role {
    allowed_member_types = ["User", "Application"]
    description          = "Admins can manage roles and perform all task actions"
    display_name         = "Admin"
    enabled              = true
    id                   = data.azuread_client_config.current.object_id
    value                = "application-administrator"
  }

  web {
    homepage_url  = var.application_fqdn
    logout_url    = "${var.application_fqdn}/signout"
    redirect_uris = ["${var.application_fqdn}/api/auth/callback/azure-ad-b2c/"]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph # Microsoft Graph

   

     resource_access {
          id   = azuread_service_principal.msgraph.app_role_ids["User.Read.All"]
          type = "Role"
        }
    
        resource_access {
          id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.ReadWrite"]# User.Read.All
          type = "Scope"
        }
      }
    }