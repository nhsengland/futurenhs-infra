output "key_vault_id" {
  value = azurerm_key_vault.main.id
}

# Returns the versionless identifier for the certificate.  REmoving the version means any certificate
# rotation in key vault should be automatically picked up by the application gateway with 24 hours
output key_vault_certificate_https_versionless_secret_id {
  value = trimsuffix(azurerm_key_vault_certificate.app_forum_https.secret_id, "${azurerm_key_vault_certificate.app_forum_https.version}")
}

output key_vault_certificate_https_name {
  value = azurerm_key_vault_certificate.app_forum_https.name
}
