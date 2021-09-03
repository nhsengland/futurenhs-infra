output app_service_name_forum {
  value = module.forum.app_service_name
}

output app_service_default_hostname_forum {
  value = module.forum.app_service_default_hostname
}

output app_service_fqdn_forum {
  value = module.forum.app_service_fqdn
}

output principal_id_forum { 
  value = module.forum.principal_id
}

output principal_id_forum_staging {
  value = module.forum.principal_id_staging
}

output principal_id_files { 
  value = module.files.principal_id
}

output principal_id_files_staging {
  value = module.files.principal_id_staging
}