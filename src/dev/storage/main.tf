# storage account used to house publically accessible artefacts such as images used for groups in the forum.  A CDN may be put in front of this

resource "azurerm_storage_account" "public_content" {
  #checkov:skip=CKV_AZURE_35:The storage account is used to serve public content over the iternet (avatar images etc) so shutting down public network access is not appropriate
  #checkov:skip=CKV_AZURE_59:The storage account is used to serve public content over the iternet (avatar images etc) so shutting down public network access is not appropriate
  #checkov:skip=CKV_AZURE_43:There is a bug in checkov (https://github.com/bridgecrewio/checkov/issues/741) that is giving a false positive on this rule so temp suppressing this rule check
  name                       = "sa${var.product_name}${var.environment}${var.location}pub"
  resource_group_name        = var.resource_group_name
  location                   = var.location

  account_tier               = "Standard"	
  account_kind               = "StorageV2"    
  account_replication_type   = "RAGRS"		  # TODO - For Production, change to RAGZRS

  access_tier                = "Hot"			

  enable_https_traffic_only  = true
  min_tls_version            = "TLS1_2"
  allow_blob_public_access   = true

  identity {
    type                     = "SystemAssigned"
  }

  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = false
    last_access_time_enabled = false

    # add the soft-delete policies to the storage account

    delete_retention_policy {
      days                   = 90  # 1 through 365      
    }

    # TODO - put this back in once the container soft delete is out of preview (https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview?tabs=powershell#register-for-the-preview)
    #container_delete_retention_policy {
    #  days                   = 90  # 1 through 365            
    #}
  }
}

data "azurerm_monitor_diagnostic_categories" "storage_category" {
  resource_id                                  = azurerm_storage_account.public_content.id
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                                         = "public-storage-account-diagnostics"
  target_resource_id                           = azurerm_storage_account.public_content.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.storage_category.logs

    content {
      category = log_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }

  dynamic "metric" {
    iterator = metric_category
    for_each = data.azurerm_monitor_diagnostic_categories.storage_category.metrics

    content {
      category = metric_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "storage_blob_category" {
  resource_id                                  = "${azurerm_storage_account.public_content.id}/blobServices/default/"
}

resource "azurerm_monitor_diagnostic_setting" "blob" {
  ## https://github.com/terraform-providers/terraform-provider-azurerm/issues/8275
  name                                         = "log-storage-account-blob-diagnostics"
  target_resource_id                           = "${azurerm_storage_account.public_content.id}/blobServices/default/"
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.storage_blob_category.logs

    content {
      category = log_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }

  dynamic "metric" {
    iterator = metric_category
    for_each = data.azurerm_monitor_diagnostic_categories.storage_blob_category.metrics

    content {
      category = metric_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }
}



# add storage container to host avatar and group images that we can serve up publically or via a CDN.
# add the connection string to the storage account to key vault for safe keeping

resource "azurerm_storage_container" "images" {
  #checkov:skip=CKV_AZURE_34:The container is used to serve public content over the iternet (avatar images etc) so shutting down public network access is not appropriate
  name                       = "images"
  storage_account_name       = azurerm_storage_account.public_content.name
  container_access_type      = "blob"	# blob | container | private
}

# add storage container to host Umbraco content that we can serve up publically or via a CDN.
# add the connection string to the storage account to key vault for safe keeping

resource "azurerm_storage_container" "content" {
  #checkov:skip=CKV_AZURE_34:The container is used to serve public content over the iternet (images etc) so shutting down public network access is not appropriate
  name                       = "content"
  storage_account_name       = azurerm_storage_account.public_content.name
  container_access_type      = "blob"	# blob | container | private
}

resource "azurerm_key_vault_secret" "blobs_primary_forum_connection_string" {
  name                                      = "blobs-${var.product_name}-${var.environment}-${var.location}-forum-connection-string"
  value                                     = azurerm_storage_account.public_content.primary_connection_string
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}

data "azurerm_key_vault_secret" "blobs_primary_api_connection_string" {
  name                                      = "blobs-${var.product_name}-${var.environment}-${var.location}-api-connection-string"
  value                                     = azurerm_storage_account.public_content.primary_connection_string
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}

resource "azurerm_key_vault_secret" "blobs_primary_umbraco_connection_string" {
  name                                      = "blobs-${var.product_name}-${var.environment}-${var.location}-umbraco-connection-string"
  value                                     = azurerm_storage_account.public_content.primary_connection_string
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}

# now add a storage container for files that are uploaded by users
# we'll add a locked immutability policy so we assure we meet the 7 years audit retention NFR and stop updates/deletion
# we'll add a stored access policy that will be used when generating SaS tokens so users can download and we can kill tokens without having the recycle the account access keys
# we'll add a connection string for the file server to pull out of key vault

resource "azurerm_storage_container" "files" {
  #checkov:skip=CKV_AZURE_34:The container is used to serve public content over the iternet (uploaded files) so shutting down public network access is not appropriate
  name                       = "files"
  storage_account_name       = azurerm_storage_account.public_content.name
  container_access_type      = "private"	# blob | container | private  # TODO - Set to private for production to assure use of Sas tokens for read only access

# TODO - unfortunately Terraform does not yet support adding access policies to storage containers so we'll need to use
#        the powershell commandlet to do this for us.  Remove this once terraform's azure resource manager adds the capability
#        NB - this requires the deployment pipeline host to have powershell and the az commands installed else it will fail
#        see https://github.com/terraform-providers/terraform-provider-azurerm/issues/3722
#        https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-immutability-policies-manage?tabs=azure-portal
#        https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-immutable-storage
#        https://docs.microsoft.com/en-us/cli/azure/storage/container/policy?view=azure-cli-latest
# TODO - Add immutability policy for Production
#        https://docs.microsoft.com/en-us/cli/azure/storage/container/immutability-policy?view=azure-cli-latest

# NB - This doesn't happen in CDS Azure environment but when trying to run on NHSi it results in a wait state in which no
# progress is made even though the resource is deployed.  The policy isn't create so the issue lies in this bit of code.
# Difficult to tell whether we fail to login or create the policy so commented out for now and will revisit when time allows 
# or there is native terraform support for management of policies

#  provisioner "local-exec" { 
#    command = <<-EOT
#              az login
#              az storage container policy create --account-name ${azurerm_storage_container.files.storage_account_name} --container-name ${azurerm_storage_container.files.name} --name sap-readonly --permissions r --auth-mode login
#    EOT
#  }
}

# TODO - Should be able to remove this later and use a managed identity to connect to the storage account from the forums app
resource "azurerm_key_vault_secret" "blobs_primary_files_connection_string" {
  name                                      = "blobs-${var.product_name}-${var.environment}-${var.location}-files-connection-string"
  value                                     = azurerm_storage_account.public_content.primary_connection_string
  key_vault_id                              = var.key_vault_id

  content_type                              = "text/plain"
  expiration_date                           = timeadd(timestamp(), "87600h")   
}




# internal storage account in which we can write private data best located outside the main database

resource "azurerm_storage_account" "private_content" {
  #checkov:skip=CKV_AZURE_43:There is a bug in checkov (https://github.com/bridgecrewio/checkov/issues/741) that is giving a false positive on this rule so temp suppressing this rule check
  name                       = "sa${var.product_name}${var.environment}${var.location}"
  resource_group_name        = var.resource_group_name
  location                   = var.location

  account_tier               = "Standard"	
  account_kind               = "StorageV2"    
  account_replication_type   = "RAGRS"		  # TODO - For Production, change to RAGZRS

  access_tier                = "Hot"			

  enable_https_traffic_only  = true
  min_tls_version            = "TLS1_2"
  allow_blob_public_access   = false

  identity {
    type                     = "SystemAssigned"
  }

  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    # add the soft-delete policies to the storage account

    delete_retention_policy {
      days                   = 90  # 1 through 365      
    }

    # TODO - put this back in once the container soft delete is out of preview (https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview?tabs=powershell#register-for-the-preview)
    #container_delete_retention_policy {
    #  days                   = 90  # 1 through 365            
    #}
  }
}

data "azurerm_monitor_diagnostic_categories" "private_storage_category" {
  resource_id                                  = azurerm_storage_account.private_content.id
}

resource "azurerm_monitor_diagnostic_setting" "private_storage" {
  name                                         = "private-storage-account-diagnostics"
  target_resource_id                           = azurerm_storage_account.private_content.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.private_storage_category.logs

    content {
      category = log_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }

  dynamic "metric" {
    iterator = metric_category
    for_each = data.azurerm_monitor_diagnostic_categories.private_storage_category.metrics

    content {
      category = metric_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "private_storage_blob_category" {
  resource_id                                  = "${azurerm_storage_account.private_content.id}/blobServices/default/"
}

resource "azurerm_monitor_diagnostic_setting" "private_blob" {
  ## https://github.com/terraform-providers/terraform-provider-azurerm/issues/8275
  name                                         = "log-storage-account-private-blob-diagnostics"
  target_resource_id                           = "${azurerm_storage_account.private_content.id}/blobServices/default/"
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.private_storage_blob_category.logs

    content {
      category = log_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }

  dynamic "metric" {
    iterator = metric_category
    for_each = data.azurerm_monitor_diagnostic_categories.private_storage_blob_category.metrics

    content {
      category = metric_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 90
      }
    }
  }
}

# add the tables used by the file server application

resource "azurerm_storage_table" "fileserver_userfileaccesstoken" {
  name                 = "FileServerWopiUserFileAccessToken"
  storage_account_name = azurerm_storage_account.private_content.name
}
#resource "azurerm_resource_group" "acr_resource_group" {
  #name     = "${var.name}-rg"
 # location = var.location
#}

#resource "azurerm_container_registry" "acr" {
 # name                = "${var.name}acr"
  #resource_group_name = azurerm_resource_group.acr_resource_group.name
  #location            = azurerm_resource_group.acr_resource_group.location
  #sku                 = "Basic"
  #admin_enabled       = false
#}
