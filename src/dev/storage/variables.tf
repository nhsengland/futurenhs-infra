variable location { type = string }

variable environment { type = string }

variable product_name { type = string }

variable resource_group_name { type = string }

variable key_vault_id { type = string }

variable log_analytics_workspace_resource_id { type = string }

variable log_storage_account_id { type = string }
variable "name" {
  type        = string
  default     = "fhnsdevcollaboraregistry"
  description = "Name for resources"
}
