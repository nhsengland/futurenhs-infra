output "virtual_network_name" {
  value = azurerm_virtual_network.main.name
}

output "network_watcher_name" { 
  value = azurerm_network_watcher.main.name
}