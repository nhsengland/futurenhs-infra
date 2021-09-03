# Temporarily disabled until we need elastic-search standing up

#data "azurerm_key_vault_secret" "elasticsearch_admin_user" {
#  name                                           = "${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-elasticsearch-adminuser"
#  key_vault_id                                   = var.key_vault_id
#}

#data "azurerm_key_vault_secret" "elasticsearch_admin_pwd" {
#  name                                           = "${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-elasticsearch-adminpwd"
#  key_vault_id                                   = var.key_vault_id
#}

#resource "azurerm_subnet" "elasticsearch" {
#  name                                           = "snet-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-elasticsearch"
#  resource_group_name                            = var.resource_group_name
#  virtual_network_name                           = var.virtual_network_name
#  address_prefixes                               = ["10.0.2.0/24"]
#
#  enforce_private_link_endpoint_network_policies = false
#  enforce_private_link_service_network_policies  = false
#}

#resource "azurerm_public_ip" "elasticsearch" {
#  name                                           = "pip-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-elasticsearch"
#  resource_group_name                            = var.resource_group_name
#  location                                       = var.location
#  allocation_method                              = "Dynamic"
#}

#resource "azurerm_network_interface" "elasticsearch" {
#  name                                           = "nic-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-elasticsearch"
#  location                                       = var.location
#  resource_group_name                            = var.resource_group_name
#
#  enable_ip_forwarding                           = false
#  enable_accelerated_networking                  = false
#
#  ip_configuration {
#    name                                         = "pip-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-elasticsearch"
#    subnet_id                                    = azurerm_subnet.elasticsearch.id
#    private_ip_address_allocation                = "Dynamic"
#    private_ip_address_version                   = "IPv4"
#    public_ip_address_id                         = azurerm_public_ip.elasticsearch.id
#  }
#}

#resource "azurerm_network_security_group" "elasticsearch" {
#  name                                           = "nsg-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-elasticsearch"
#  location                                       = var.location
#  resource_group_name                            = var.resource_group_name
#
#  security_rule {
#    access                                       = "Allow"
#    direction                                    = "Inbound"
#    name                                         = "tls"
#    priority                                     = 100
#    protocol                                     = "Tcp"
#    source_port_range                            = "*"
#    source_address_prefix                        = "*"
#    destination_port_range                       = "443"
#    destination_address_prefix                   = azurerm_network_interface.elasticsearch.private_ip_address
#  }
#}

#resource "azurerm_network_interface_security_group_association" "elasticsearch" {
#  network_interface_id                           = azurerm_network_interface.elasticsearch.id
#  network_security_group_id                      = azurerm_network_security_group.elasticsearch.id
#}

#resource "azurerm_linux_virtual_machine" "elasticsearch" {
#  name                                           = "vm-${lower(var.product_name)}-${lower(var.environment)}-${lower(var.location)}-elasticsearch"
#  resource_group_name                            = var.resource_group_name
#  location                                       = var.location
#  size                                           = "Standard_F2s_v2"
#  admin_username                                 = data.azurerm_key_vault_secret.elasticsearch_admin_user.value
#  admin_password                                 = data.azurerm_key_vault_secret.elasticsearch_admin_pwd.value
#  disable_password_authentication                = false
#  network_interface_ids = [
#    azurerm_network_interface.elasticsearch.id,
#  ]
#
#  source_image_reference {
#    publisher = "Canonical"
#    offer     = "UbuntuServer"
#    sku       = "16.04-LTS"
#    version   = "latest"
#  }
#
#  os_disk {
#    storage_account_type = "Standard_LRS"
#    caching              = "ReadOnly"
#
#    diff_disk_settings {
#      option = "Local"
#    }
#  }
#}