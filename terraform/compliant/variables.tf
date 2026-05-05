variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "location" {
  type        = string
  description = "Azure region — must be an EU region to satisfy R-06"
  default     = "swedencentral"
}

variable "environment" {
  type        = string
  description = "Environment tag value"
  default     = "dev"
}

variable "owner" {
  type        = string
  description = "Owner tag value"
  default     = "team-platform"
}

variable "cost_center" {
  type        = string
  description = "Cost center tag value"
  default     = "cc-001"
}

variable "principal_id" {
  type        = string
  description = "Object ID of the Azure AD principal for the role assignment"
}

variable "admin_username" {
  type        = string
  description = "Admin username for VM and SQL Server — avoid generic names like 'admin' or 'root'"
  default     = "thesisadmin"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access. Generate with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/thesis_vm_key"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "Administrator password for SQL Server — min 8 chars, must include uppercase, lowercase, number, and special character"
}
