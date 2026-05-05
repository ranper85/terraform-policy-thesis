variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "Administrator password for SQL Server — min 8 chars, must include uppercase, lowercase, number, and special character"
}
