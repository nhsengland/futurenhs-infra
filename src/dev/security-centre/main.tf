data "azurerm_subscription" "current" {
}

resource "azurerm_security_center_subscription_pricing" "appsvc" {
  tier = "Standard"
  resource_type = "AppServices"
}

resource "azurerm_security_center_subscription_pricing" "sqlsvr" {
  tier = "Standard"
  resource_type = "SqlServers"
}

resource "azurerm_security_center_subscription_pricing" "virmac" {
  tier = "Standard"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "stracc" {
  tier = "Standard"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "keyvlt" {
  tier = "Standard"
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_subscription_pricing" "azresmn" {
  tier = "Standard"
  resource_type = "Arm"
}

resource "azurerm_security_center_subscription_pricing" "dns" {
  tier = "Standard"
  resource_type = "Dns"
}


resource "azurerm_security_center_workspace" "main" {
  scope             = data.azurerm_subscription.current.id
  workspace_id      = var.log_analytics_workspace_resource_id

  depends_on = [
    azurerm_security_center_subscription_pricing.appsvc
  ]
}

resource "azurerm_security_center_contact" "main" {
  email               = var.security_center_contact_email
  phone               = var.security_center_contact_phone
  alert_notifications = true
  alerts_to_admins    = true

  depends_on = [
    azurerm_security_center_workspace.main,
    azurerm_security_center_subscription_pricing.appsvc
  ]
}

resource "azurerm_security_center_auto_provisioning" "main" {
  auto_provision = "On"
}