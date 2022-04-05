resource "azurerm_network_watcher_flow_log" "default" {
  network_watcher_name                           = var.network_watcher_name
  resource_group_name                            = azurerm_network_security_group.default.resource_group_name

  network_security_group_id                      = azurerm_network_security_group.default.id
  storage_account_id                             = var.log_storage_account_id
  enabled                                        = true
  version                                        = 2

  retention_policy {
    enabled                                      = true
    days                                         = 120
  }
 
  traffic_analytics {
    enabled                                      = true
    workspace_id                                 = var.log_analytics_workspace_id
    workspace_region                             = var.location
    workspace_resource_id                        = var.log_analytics_workspace_resource_id
    interval_in_minutes                          = 10
  }
}

resource "azurerm_subnet" "default" {
  name                                           = "snet-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-default"
  resource_group_name                            = azurerm_network_security_group.default.resource_group_name
  virtual_network_name                           = var.virtual_network_name
  address_prefixes                               = ["10.0.1.0/24"]

  enforce_private_link_endpoint_network_policies = false
  enforce_private_link_service_network_policies  = false

  service_endpoints                              = [
    #"Microsoft.KeyVault",
    #"Microsoft.Sql", 
    #"Microsoft.Storage",
    "Microsoft.Web"
  ]
}

resource "azurerm_public_ip" "default" {
  name                                           = "pip-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-default"
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  sku                                            = "Standard"
  allocation_method                              = "Static"
  domain_name_label                              = "${lower(var.product_name)}-${lower(var.environment)}"
}

data "azurerm_monitor_diagnostic_categories" "pip" {
  resource_id                                  = azurerm_public_ip.default.id
}

resource "azurerm_monitor_diagnostic_setting" "pip" {
  name                                         = "pip-diagnostics"
  target_resource_id                           = azurerm_public_ip.default.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.pip.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.pip.metrics

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

resource "azurerm_network_security_group" "default" {
  name                                           = "nsg-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-default"
  location                                       = var.location
  resource_group_name                            = var.resource_group_name
}

# We need a security rule to allow the Application Gateway to communicate 
# https://docs.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#network-security-groups

resource "azurerm_network_security_rule" "allow_gateway_manager_inbound" {
  name                                           = "AllowGatewayManagerInbound"
  description                                    = "Authorise App Gateway Manager"
  priority                                       = 100 # 100 - 4096
  direction                                      = "Inbound" # Inbound | Outbound
  access                                         = "Allow" # Allow | Deny
  protocol                                       = "Tcp" # Tcp | Udp | Icmp | Esp | Ah | *
  source_port_range                              = "*"
  destination_port_range                         = "65200-65535"
  source_address_prefix                          = "GatewayManager"
  destination_address_prefix                     = "*"
  resource_group_name                            = var.resource_group_name
  network_security_group_name                    = azurerm_network_security_group.default.name
}

# Open up access to application insights so it can run web tests (not necessary to include here given the web site is 
# publically available, but may want to use web tests to track SLAs for services we host inside out vnet in the future)

resource "azurerm_network_security_rule" "allow_appinsights_web_tests" {
  name                                           = "AllowAppInsightsWebTestsInbound"
  description                                    = "Authorise Http(s) web tests coming from Azure Monitor App Insights"
  priority                                       = 101 
  direction                                      = "Inbound" 
  access                                         = "Allow" 
  protocol                                       = "Tcp" 
  source_port_range                              = "*"
  destination_port_ranges                        = [ "80", "443" ]
  source_address_prefix                          = "ApplicationInsightsAvailability"
  destination_address_prefix                     = "*"
  resource_group_name                            = var.resource_group_name
  network_security_group_name                    = azurerm_network_security_group.default.name
}

# Open up access to public over http/s

resource "azurerm_network_security_rule" "allow_public_http_inbound" {
  name                                           = "AllowPublicHttpInbound"
  description                                    = "Authorise Http(s) requests from the internet to access the web application"
  priority                                       = 102
  direction                                      = "Inbound" 
  access                                         = "Allow" 
  protocol                                       = "Tcp" 
  source_port_range                              = "*"
  destination_port_ranges                        = [ "80", "443" ]
  source_address_prefix                          = "*"
  destination_address_prefix                     = "*"
  resource_group_name                            = var.resource_group_name
  network_security_group_name                    = azurerm_network_security_group.default.name
}

data "azurerm_monitor_diagnostic_categories" "nsg" {
  resource_id                                  = azurerm_network_security_group.default.id
}

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  name                                         = "nsg-diagnostics"
  target_resource_id                           = azurerm_network_security_group.default.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.nsg.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.nsg.metrics

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

resource "azurerm_subnet_network_security_group_association" "default_subnet" {
  subnet_id                                      = azurerm_subnet.default.id
  network_security_group_id                      = azurerm_network_security_group.default.id

  depends_on = [ 
    azurerm_network_security_rule.allow_gateway_manager_inbound  
  ]
}

resource "azurerm_application_gateway" "default" {
  name                                           = "agw-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-default"
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  zones                                          = ["1","2","3"]
  enable_http2                                   = true  

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_app_gateway]
  }

  autoscale_configuration {
    min_capacity                                 = 1   # min = 1, max = 100
    max_capacity                                 = 2   # min = 2, max = 125
  }

  waf_configuration {
    enabled                                      = true
    firewall_mode                                = "Detection" # Detection | Prevention
    rule_set_type                                = "OWASP"
    rule_set_version                             = "3.2"
    file_upload_limit_mb                         = 250  # can go up to 750MB for OWASP3.1 and 4GB for 3.2
    request_body_check                           = true
    max_request_body_size_kb                     = 128    
  }

  gateway_ip_configuration {
    name                                         = "agw-ipconfig"
    subnet_id                                    = azurerm_subnet.default.id
  }

  frontend_port {
    name                                         = "agw-frontend-port-443"
    port                                         = 443
  }

  frontend_port {
    name                                         = "agw-frontend-port-80"
    port                                         = 80
  }

  frontend_ip_configuration {
    name                                         = "agw-frontend-ipconfig-public"
    public_ip_address_id                         = azurerm_public_ip.default.id
  }

  http_listener {
    name                                         = "agw-80-listener"
    frontend_ip_configuration_name               = "agw-frontend-ipconfig-public"
    frontend_port_name                           = "agw-frontend-port-80"
    protocol                                     = "Http"
  }

  http_listener {
    name                                         = "agw-443-listener"
    frontend_ip_configuration_name               = "agw-frontend-ipconfig-public"
    frontend_port_name                           = "agw-frontend-port-443"
    protocol                                     = "Https"
    ssl_certificate_name                         = var.key_vault_certificate_https_name
  }

  ssl_certificate {
    name                                         = var.key_vault_certificate_https_name
    key_vault_secret_id                          = var.key_vault_certificate_https_versionless_secret_id
  }

  # For images such as group header or avatars, we want to serve direct from blob storage but hidden behind 
  # a url that ties to our website.
  # Define a rewrite rule set that picks up a reserved path, and structures the url as the blob store expects
  # noting that we need to pass through query parameters if using Sas Tokens to control blob access

  # list of supported server variables at https://docs.microsoft.com/en-us/azure/application-gateway/rewrite-http-headers-url#server-variables
  # details of syntax to reference variables at https://docs.microsoft.com/en-us/azure/application-gateway/rewrite-http-headers-url

  rewrite_rule_set {
    name                                         = "agw-rewrite-request-rule-set"

    rewrite_rule {
      name                                       = "agw-rewrite-media-request-url"
      rule_sequence                              = 101

      # if the uri_path variable matches the */gateway/media/<container/file> pattern, we want to reroute to the 
      # blob storage account, noting the container and file name need to be copied over, along with any query
      # string as it may contain a sas token

      condition {
        variable                                 = "var_uri_path"
        pattern                                  = ".*/gateway/media/(.*)" # .*\.(gif|jpg|png)$
        ignore_case                              = true 
        negate                                   = false 
      }

      url {
        path                                     = "{var_uri_path_1}" 
        query_string                             = "{var_query_string}" # https://github.com/terraform-providers/terraform-provider-azurerm/issues/11563
        reroute                                  = false
      }
    }

    rewrite_rule {
      name                                       = "agw-rewrite-files-request-url"
      rule_sequence                              = 102

      # if the uri_path variable matches the */gateway/wopi/host/<sub-path> pattern, we want to reroute to the 
      # file server app service

      condition {
        variable                                 = "var_uri_path"
        pattern                                  = ".*/gateway/wopi/host/(.*)"
        ignore_case                              = true 
        negate                                   = false 
      }

      url {
        path                                     = "wopi/{var_uri_path_1}" 
        query_string                             = "{var_query_string}" # https://github.com/terraform-providers/terraform-provider-azurerm/issues/11563
        reroute                                  = false
      }

     # Set the Location header on requests bound for our file server.  This is because Collabora signs requests using the app gw url and not 
     # the backend url of the consuming service.   The file server needs to know what Collabora used so it can verify the signature.  It checks
     # for and uses the value in the Location header for this purpose (if it is present)

      request_header_configuration {
        header_name                              = "Location"
        header_value                             = "https://{var_host}{var_request_uri}" 
      }
    }    

    rewrite_rule {
      name                                       = "agw-rewrite-api-health-check-request-url"
      rule_sequence                              = 103

      condition {
        variable                                 = "var_uri_path"
        pattern                                  = ".*/gateway/api/health-check" 
        ignore_case                              = true 
        negate                                   = false 
      }

      url {
        path                                     = "health-check" 
        query_string                             = "" 
        reroute                                  = false
      }
    }
 
    rewrite_rule {
      name                                       = "agw-rewrite-api-request-url"
      rule_sequence                              = 104

      # if the uri_path variable matches the */gateway/api/* pattern, we want to reroute to the 
      # API backend service

      condition {
        variable                                 = "var_uri_path"
        pattern                                  = ".*/gateway/api/(.*)" 
        ignore_case                              = true 
        negate                                   = false 
      }

      url {
        path                                     = "api/{var_uri_path_1}" 
        query_string                             = "{var_query_string}" 
        reroute                                  = false
      }
    }


    rewrite_rule {
      name                                       = "agw-rewrite-mvcforum-members"
      rule_sequence                              = 105

      # if the uri_path variable matches the */gateway/api/* pattern, we want to reroute to the 
      # API backend service

      condition {
        variable                                 = "var_uri_path"
        pattern                                  = ".*/members/(.*)" 
        ignore_case                              = true 
        negate                                   = false 
      }

      url {
        path                                     = "{var_uri_path_1}" 
        query_string                             = "{var_query_string}" 
        reroute                                  = false
      }
    }

    
      rewrite_rule {
      name                                       = "agw-rewrite-mvcforum-ui"
      rule_sequence                              = 106

      # if the uri_path variable matches the */gateway/api/* pattern, we want to reroute to the 
      # API backend service

      condition {
        variable                                 = "var_uri_path"
        pattern                                  = ".*/ui/(.*)" 
        ignore_case                              = true 
        negate                                   = false 
      }

      url {
        path                                     = "{var_uri_path_1}" 
        query_string                             = "{var_query_string}" 
        reroute                                  = false
      }
    }

   }

  # Forum rules to remove headers from outbound requests that can be considered to be security risks
  # e.g. headers that could help an attacker identify the host of the web server and thus attack it with 
  #      known security vulnerabilities

  rewrite_rule_set {
    name                                         = "agw-rewrite-response-rule-set"

    rewrite_rule {
      name                                       = "agw-remove-insecure-response-headers"
      rule_sequence                              = 100

      response_header_configuration {
        header_name                              = "X-Powered-By"
        header_value                             = ""  # Empty string instructs the removal of the header from the response
      }      

      response_header_configuration {
        header_name                              = "X-AspNet-Version"
        header_value                             = ""  
      }      

      response_header_configuration {
        header_name                              = "X-AspNetMVC-Version"
        header_value                             = ""  
      }      
    }
  }


  # Rules to route requests to the appropriate backend service
  # First up, automatically redirect all http request over to https

  redirect_configuration {
    name                                         = "agw-redirecting-80-to-443"
    redirect_type                                = "Permanent"
    include_path                                 = true
    include_query_string                         = true
    target_listener_name                         = "agw-443-listener"
  }

  request_routing_rule {
    name                                         = "agw-routing-80"
    rule_type                                    = "Basic"
    http_listener_name                           = "agw-80-listener"
    redirect_configuration_name                  = "agw-redirecting-80-to-443"
  }

  # Next up, we need routing rules for https traffic to the relevant back end servers
 
  # Website requests need to be sent to the old forum app service.  This will be the default behaviour
  # given the routing rules backend address pool is the forum, however this will eventually be replaced
  # once the vNext web app is able to serve all traffic

  request_routing_rule {
    name                                         = "agw-routing-443"
    rule_type                                    = "PathBasedRouting"  # Basic
    http_listener_name                           = "agw-443-listener"
    url_path_map_name                            = "agw-routing-url-path-map"
  }

  # We will use a path based routing algo to detect the correct backend service to route to.  
  # 1. For public blobs such as avatar images & files we will route to the blob storage service housing them
  # 2. For file upload requests we need to route to our file server servers
  # 3. For file viewing/editing we need to route to the Collabora servers (requires server affinity)
  # 4. For website requests, we route to our forum servers - this is the default behaviour if no rules match

  url_path_map {
    name                                         = "agw-routing-url-path-map"
    default_backend_address_pool_name            = "agw-web-backend-address-pool"
    default_backend_http_settings_name           = "agw-web-backend-https"
    default_rewrite_rule_set_name                = "agw-rewrite-response-rule-set"

    # We do not need to add a custom /* path rule to handle default cases. 
    # This is automatically handled by the default backend pool which directs to the old MVCForum web site.

    path_rule {
      name                                       = "agw-routing-url-path-map-rule-to-blob"
      paths                                      = ["/gateway/media/*"]
      backend_address_pool_name                  = "agw-blob-backend-address-pool"
      backend_http_settings_name                 = "agw-blob-backend-https"
      rewrite_rule_set_name                      = "agw-rewrite-request-rule-set" 
    }

    path_rule {
      name                                       = "agw-routing-url-path-map-rule-to-file-server"
      paths                                      = ["/gateway/wopi/host/*"]
      backend_address_pool_name                  = "agw-files-backend-address-pool"
      backend_http_settings_name                 = "agw-files-backend-https"
      rewrite_rule_set_name                      = "agw-rewrite-request-rule-set" 
    }

    path_rule {
      name                                       = "agw-routing-url-path-map-rule-to-collabora"
      paths                                      = ["/gateway/wopi/client/*"]
      backend_address_pool_name                  = "agw-collabora-backend-address-pool"
      backend_http_settings_name                 = "agw-collabora-backend-https"
      rewrite_rule_set_name                      = "agw-rewrite-request-rule-set" 
    }

    path_rule {
      name                                       = "agw-routing-url-path-map-rule-to-api"
      paths                                      = ["/gateway/api/*"]
      backend_address_pool_name                  = "agw-api-backend-address-pool"
      backend_http_settings_name                 = "agw-api-backend-https"
      rewrite_rule_set_name                      = "agw-rewrite-request-rule-set" 
    }

    path_rule {
      name                                       = "agw-routing-url-path-map-rule-to-mvcforum-ui"
      paths                                      = ["/ui/*"]
      backend_address_pool_name                  = "agw-forum-backend-address-pool"
      backend_http_settings_name                 = "agw-forum-backend-https"
      rewrite_rule_set_name                      = "agw-rewrite-request-rule-set" 
    }
    path_rule {
      name                                       = "agw-routing-url-path-map-rule-to-mvcforum-members"
      paths                                      = ["/members/*"]
      backend_address_pool_name                  = "agw-forum-backend-address-pool"
      backend_http_settings_name                 = "agw-forum-backend-https"
      rewrite_rule_set_name                      = "agw-rewrite-request-rule-set" 
    }
  }



  # Configure the back end settings for the various target services we route to

  # 1. Forum web site

  backend_http_settings {
    name                                         = "agw-forum-backend-https"
    cookie_based_affinity                        = "Disabled"
    #affinity_cookie_name                         = ""
    #path                                         = "/"
    port                                         = 443
    protocol                                     = "Https"
    request_timeout                              = 30
    probe_name                                   = "agw-forum-probe"
    #host_name                                    = "futurenhs.cds.co.uk" 
    pick_host_name_from_backend_address          = true
  }

  probe {
    name                                         = "agw-forum-probe"
    interval                                     = 30 # 1 - 86400
    protocol                                     = "Https"
    path                                         = "/api/HealthCheck/heartbeat"
    timeout                                      = 30 # 1 - 86400
    unhealthy_threshold                          = 3 # 1 - 20
    #port                                         = "443"
    pick_host_name_from_backend_http_settings    = true
    minimum_servers                              = 0

    match {
      status_code                                = [ "200" ]    # TODO: 200-399?
    } 
  }

  backend_address_pool {
    name                                         = "agw-forum-backend-address-pool"
    fqdns                                        = [
      "app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-forum.azurewebsites.net"
    ]
  }

  # 2. Public blob storage to serve up avatar/group images eand files
  
  backend_http_settings {
    name                                         = "agw-blob-backend-https"
    cookie_based_affinity                        = "Disabled"
    #affinity_cookie_name                         = ""
    #path                                         = "/"
    port                                         = 443
    protocol                                     = "Https"
    request_timeout                              = 30
    probe_name                                   = "agw-blob-probe"
    pick_host_name_from_backend_address          = true    
  }

  probe {
    name                                         = "agw-blob-probe"
    interval                                     = 30 # 1 - 86400
    protocol                                     = "Https"
    path                                         = "/"
    timeout                                      = 30 # 1 - 86400
    unhealthy_threshold                          = 3 # 1 - 20
    #port                                         = "443"
    pick_host_name_from_backend_http_settings    = true
    minimum_servers                              = 0

    match {
      status_code                                = [ "400" ]
    } 
  }

  backend_address_pool {
    name                                         = "agw-blob-backend-address-pool"
    fqdns                                        = [
      var.forum_primary_blob_fqdn   
    ]
  }

  # 3. Stand alone WOPI Host (File Server)

  backend_http_settings {
    name                                         = "agw-files-backend-https"
    cookie_based_affinity                        = "Disabled"
    #affinity_cookie_name                         = ""
    #path                                         = "/"
    port                                         = 443
    protocol                                     = "Https"
    request_timeout                              = 30
    probe_name                                   = "agw-files-probe"
    pick_host_name_from_backend_address          = true    
  }

  probe {
    name                                         = "agw-files-probe"
    interval                                     = 30 # 1 - 86400
    protocol                                     = "Https"
    path                                         = "/wopi/health-check"
    timeout                                      = 30 # 1 - 86400
    unhealthy_threshold                          = 3 # 1 - 20
    #port                                         = "443"
    pick_host_name_from_backend_http_settings    = true
    minimum_servers                              = 0

    match {
      status_code                                = [ "200" ]
    } 
  }

  backend_address_pool {
    name                                         = "agw-files-backend-address-pool"
    fqdns                                        = [
      "app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-files.azurewebsites.net"   
    ]
  }

  # 4. Stand alone WOPI Client (Collabora)

  backend_http_settings {
    name                                         = "agw-collabora-backend-https"
    cookie_based_affinity                        = "Enabled"
    affinity_cookie_name                         = "${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-collabora-gwaffinity"
    #path                                         = "/"
    port                                         = 443
    protocol                                     = "Https"
    request_timeout                              = 30
    probe_name                                   = "agw-collabora-probe"
    pick_host_name_from_backend_address          = true    
  }

  probe {
    name                                         = "agw-collabora-probe"
    interval                                     = 30 # 1 - 86400
    protocol                                     = "Https"
    path                                         = "/gateway/wopi/client/hosting/discovery"
    timeout                                      = 30 # 1 - 86400
    unhealthy_threshold                          = 3 # 1 - 20
    #port                                         = "443"
    pick_host_name_from_backend_http_settings    = true
    minimum_servers                              = 0

    match {
      status_code                                = [ "200" ]
    } 
  }

  backend_address_pool {
    name                                         = "agw-collabora-backend-address-pool"
    fqdns                                        = [
      "app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-collabora.azurewebsites.net"   
    ]
  }

  # 5. API Host Service

  backend_http_settings {
    name                                         = "agw-api-backend-https"
    cookie_based_affinity                        = "Disabled"
    #affinity_cookie_name                         = ""
    #path                                         = "/"
    port                                         = 443
    protocol                                     = "Https"
    request_timeout                              = 30
    probe_name                                   = "agw-api-probe"
    pick_host_name_from_backend_address          = true    
  }

  probe {
    name                                         = "agw-api-probe"
    interval                                     = 30 # 1 - 86400
    protocol                                     = "Https"
    path                                         = "/health-check"
    timeout                                      = 30 # 1 - 86400
    unhealthy_threshold                          = 3 # 1 - 20
    #port                                         = "443"
    pick_host_name_from_backend_http_settings    = true
    minimum_servers                              = 0

    match {
      status_code                                = [ "200" ]
    } 
  }

  backend_address_pool {
    name                                         = "agw-api-backend-address-pool"
    fqdns                                        = [
      "app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-api.azurewebsites.net"   
    ]
  }

  # 6. vNext Web (MVCForum replacement) Host Service

  backend_http_settings {
    name                                         = "agw-web-backend-https"
    cookie_based_affinity                        = "Disabled"
    #affinity_cookie_name                         = ""
    #path                                         = "/"
    port                                         = 443
    protocol                                     = "Https"
    request_timeout                              = 30
    probe_name                                   = "agw-web-probe"
    pick_host_name_from_backend_address          = true    
  }

  probe {
    name                                         = "agw-web-probe"
    interval                                     = 30 # 1 - 86400
    protocol                                     = "Https"
    path                                         = "/health-check"
    timeout                                      = 30 # 1 - 86400
    unhealthy_threshold                          = 3 # 1 - 20
    #port                                         = "443"
    pick_host_name_from_backend_http_settings    = true
    minimum_servers                              = 0

    match {
      status_code                                = [ "200" ]
    } 
  }

  backend_address_pool {
    name                                         = "agw-web-backend-address-pool"
    fqdns                                        = [
      "app-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-web.azurewebsites.net"   
    ]
  }

}

data "azurerm_monitor_diagnostic_categories" "agw_waf" {
  resource_id                                  = azurerm_application_gateway.default.id
}

resource "azurerm_monitor_diagnostic_setting" "agw-waf" {
  name                                         = "agw-waf-diagnostics"
  target_resource_id                           = azurerm_application_gateway.default.id
  log_analytics_workspace_id                   = var.log_analytics_workspace_resource_id
  storage_account_id                           = var.log_storage_account_id

  dynamic "log" {
    iterator = log_category
    for_each = data.azurerm_monitor_diagnostic_categories.agw_waf.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.agw_waf.metrics

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
