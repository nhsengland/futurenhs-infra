# Standard SKU minimum needed for dedicated cluster and partitioning to assure 99.9% uptime SLA

#resource "azurerm_search_service" "main" {
#  name                		= "srch-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-001"
#  resource_group_name 		= var.resource_group_name
#  location            		= var.location
#  sku                 		= "basic"			# changing forces recreation - free | basic | standard | standard2 | standard3 | storage_optimized_l1 | storage_optimized_l2

#  public_network_access_enabled = true

#  identity {
#    type 			= "SystemAssigned"
#  }
  
#  #partition_count		= 3				# only available for sku level >= standard
#  #replica_count		= 3				# only available for sku level >= standard

#  #allowed_ips			= []				
#}

#data "azurerm_monitor_diagnostic_categories" "srch" {
#  resource_id                                  = azurerm_search_service.main.id
#}

#resource "azurerm_monitor_diagnostic_setting" "pip" {
#  name                                         = "srch-diagnostics"
#  target_resource_id                           = azurerm_search_service.main.id
#  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
#  storage_account_id                           = var.log_storage_account_id

#  dynamic "log" {
#    iterator = log_category
#    for_each = data.azurerm_monitor_diagnostic_categories.srch.logs

#    content {
#      category = log_category.value
#      enabled  = true

#      retention_policy {
#        enabled = true
#        days    = 90
#      }
#    }
#  }

#  dynamic "metric" {
#    iterator = metric_category
#    for_each = data.azurerm_monitor_diagnostic_categories.srch.metrics

#    content {
#      category = metric_category.value
#      enabled  = true

#      retention_policy {
#        enabled = true
#        days    = 90
#      }
#    }
#  }
#}



# PUT request to create Cognitive Search data source that links to the forum database to index searching for groups

#locals {
#  forum_search_data_source_name             = var.forum_sql_database_name

#  forum_search_data_source_parameters = {
#    search_data_source_name                 = local.forum_search_data_source_name
#    connection_string                       = var.forum_database_connection_string
#    view_name                               = "[dbo].[vw_search_groups]"
#  }

#  forum_raw_search_data_source_config       = templatefile("${path.module}/forumdb_search_data_source.json", local.forum_search_data_source_parameters)

#  forum_search_data_source_config           = replace(replace(local.forum_raw_search_data_source_config, "\n", " "), "\"", "\\\"") 
#}

#resource "null_resource" "terraform-debug" {
#  provisioner "local-exec" {
#    command = "echo $VARIABLE1" # >> debug.txt ; echo $VARIABLE2 >> debug.txt ; echo $VARIABLE3 >> debug.txt"
#
#    environment = {
#        VARIABLE1 = jsonencode(local.forum_search_data_source_name)
#        VARIABLE2 = jsonencode(local.forum_search_data_source_config)
#    }
#  }
#}


## TODO - Comment this back in once I've figured out why curl errors when negotiating https connection
##        Also, need to extend the config to create the relevant indexers, indexes and skills
##        See https://github.com/rozele/azure-cognitive-search-skills-terraform/blob/main/deploy/terraform/search.tf for example

#resource "null_resource" "forumdb_search_data_source" {
#  triggers = {
#    configuration = sha256(local.forum_search_data_source_config)
#  }
#  provisioner "local-exec" {
#    command = <<EOF
#      curl --location --request PUT "https://${azurerm_search_service.main.name}.search.windows.net/datasources/${local.forum_search_data_source_name}?api-version=2020-06-30" \
#        --header "api-key: ${azurerm_search_service.main.primary_key}" \
#        --header "Content-Type: application/json" \
#        --data "${local.forum_search_data_source_config}"
#    EOF
#  }
#}