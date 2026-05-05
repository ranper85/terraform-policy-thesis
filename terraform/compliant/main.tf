# Compliant Terraform configuration — passes all 9 policy rules
# Used to verify that valid configurations are not incorrectly rejected.

data "azurerm_client_config" "current" {}

locals {
  # R-07: all three required tags present
  tags = {
    environment   = var.environment
    owner         = var.owner
    "cost-center" = var.cost_center
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-compliant-dev"
  location = var.location # R-06: approved EU region
  tags     = local.tags
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-compliant"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "main" {
  name                 = "subnet-compliant"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "nic-compliant"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# --- Key Vault + Key (R-08: encryption at rest) ---

resource "azurerm_key_vault" "main" {
  name                       = "kv-thesis-compliant" # must be globally unique in Azure, max 24 chars
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true # required by Azure when used with disk encryption sets
  soft_delete_retention_days = 7
  tags                       = local.tags
}

# Least privilege: grant only the deploying identity permission to create/manage keys
resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create", "Delete", "Get", "List",
    "Purge", "Recover", "Update",
    "GetRotationPolicy", "SetRotationPolicy",
  ]
}

resource "azurerm_key_vault_key" "main" {
  name         = "des-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  depends_on = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_disk_encryption_set" "main" {
  name                = "des-compliant"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  key_vault_key_id    = azurerm_key_vault_key.main.id # R-08: references key created above
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }
}

# Least privilege: grant DES managed identity only the minimum permissions to use the key
resource "azurerm_key_vault_access_policy" "des" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_disk_encryption_set.main.identity[0].principal_id

  key_permissions = ["Get", "WrapKey", "UnwrapKey"]
}

# --- Virtual Machine ---

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "vm-compliant"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location # R-06: approved EU region
  size                            = "Standard_B2als_v2"                  # R-01: allowed size
  admin_username                  = var.admin_username
  disable_password_authentication = true # SSH only — no password login allowed
  network_interface_ids           = [azurerm_network_interface.main.id]
  tags                            = local.tags # R-07: all required tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key # R-safe: key provided via variable, never hardcoded
  }

  os_disk {
    caching                = "ReadWrite"
    storage_account_type   = "Standard_LRS"
    disk_encryption_set_id = azurerm_disk_encryption_set.main.id # R-08: encrypted
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# --- Storage Account ---

resource "azurerm_storage_account" "main" {
  name                            = "stcompliantdev001"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location # R-06: approved EU region
  account_tier                    = "Standard"                           # R-02: Standard only
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false      # R-03: no public blob access
  https_traffic_only_enabled      = true       # R-03: HTTPS enforced
  tags                            = local.tags # R-07: all required tags
}

# --- IAM ---

resource "azurerm_role_assignment" "main" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader" # R-04: least-privilege role
  principal_id         = var.principal_id
}

# --- Network Security ---

resource "azurerm_network_security_group" "main" {
  name                = "nsg-compliant"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "allow-ssh-restricted"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "10.0.0.0/24" # R-05: restricted to known IP, not 0.0.0.0/0
  destination_address_prefix  = "*"
}

# --- Managed Disk ---

resource "azurerm_managed_disk" "main" {
  name                   = "disk-compliant"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location # R-06: approved EU region
  storage_account_type   = "Standard_LRS"
  create_option          = "Empty"
  disk_size_gb           = 64
  disk_encryption_set_id = azurerm_disk_encryption_set.main.id # R-08: encryption at rest
  tags                   = local.tags                          # R-07: all required tags
}

# --- SQL Server + Firewall (R-09) ---

resource "azurerm_mssql_server" "main" {
  name                         = "sql-thesis-compliant-dev" # must be globally unique in Azure
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = var.sql_admin_password
  tags                         = local.tags
}

resource "azurerm_mssql_firewall_rule" "main" {
  name             = "sql-fw-office"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "10.0.0.1" # R-09: specific IP range only
  end_ip_address   = "10.0.0.10"
}
