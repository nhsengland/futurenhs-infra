output instrumentation_key {
  value     = module.forum_production_slot.instrumentation_key
  sensitive = true
}

output connection_string {
  value     = module.forum_production_slot.connection_string
  sensitive = true
}

output staging_instrumentation_key {
  value     = module.forum_staging_slot.instrumentation_key
  sensitive = true
}

output staging_connection_string {
  value     = module.forum_staging_slot.connection_string
  sensitive = true
}