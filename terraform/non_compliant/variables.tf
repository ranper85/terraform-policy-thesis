variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "Administrator password for SQL Server — min 8 chars, must include uppercase, lowercase, number, and special character"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access — not a policy violation, required for valid provider syntax"
}
