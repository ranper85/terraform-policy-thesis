# Non-compliant Terraform configuration — violates all 9 policy rules
# Used to verify that policy violations are correctly detected.

resource "azurerm_resource_group" "main" {
  name     = "rg-non-compliant"
  location = "eastus" # R-06 VIOLATION: non-EU region
  # R-07 VIOLATION: missing required tags (environment, owner, cost-center)
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-non-compliant"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  name                 = "subnet-non-compliant"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "nic-non-compliant"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = "vm-non-compliant"
  resource_group_name   = azurerm_resource_group.main.name
  location              = "eastus"          # R-06 VIOLATION: non-EU region
  size                  = "Standard_D4s_v3" # R-01 VIOLATION: size not in allowed list
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.main.id]
  # R-07 VIOLATION: missing required tags

  admin_ssh_key {
    username   = "adminuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC demo-key"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    # R-08 VIOLATION: no disk_encryption_set_id configured
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_storage_account" "main" {
  name                            = "stnoncompdev001"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = "eastus"  # R-06 VIOLATION: non-EU region
  account_tier                    = "Premium" # R-02 VIOLATION: Premium tier not allowed
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true  # R-03 VIOLATION: public blob access enabled
  https_traffic_only_enabled      = false # R-03 VIOLATION: HTTP traffic allowed
  # R-07 VIOLATION: missing required tags
}

resource "azurerm_role_assignment" "main" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Owner" # R-04 VIOLATION: overly permissive role
  principal_id         = "00000000-0000-0000-0000-000000000000"
}

resource "azurerm_network_security_group" "main" {
  name                = "nsg-non-compliant"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "allow-ssh-internet"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "0.0.0.0/0" # R-05 VIOLATION: SSH open to entire internet
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "rdp" {
  name                        = "allow-rdp-internet"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*" # R-05 VIOLATION: RDP open to entire internet
  destination_address_prefix  = "*"
}

resource "azurerm_managed_disk" "main" {
  name                 = "disk-non-compliant"
  resource_group_name  = azurerm_resource_group.main.name
  location             = "eastus" # R-06 VIOLATION: non-EU region
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 64
  # R-08 VIOLATION: no encryption configured
  # R-07 VIOLATION: missing required tags
}

resource "azurerm_mssql_server" "main" {
  name                         = "sql-thesis-noncmpl-dev" # must be globally unique in Azure
  resource_group_name          = azurerm_resource_group.main.name
  location                     = "eastus" # R-06 VIOLATION: non-EU region
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  # R-07 VIOLATION: missing required tags
}

resource "azurerm_mssql_firewall_rule" "main" {
  name             = "sql-fw-all"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"       # R-09 VIOLATION: open to all IP addresses
  end_ip_address   = "255.255.255.255"
}
