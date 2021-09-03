output forum_keyvault_connection_string_reference {
  value       = module.forum.keyvault_connection_string_reference
}

output forum_database_name {
  value       = module.forum.database_name
}

output forum_connection_string { 
  value       = module.forum.connection_string
  sensitive   = true
}