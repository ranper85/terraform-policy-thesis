# Compliant Terraform configuration — passes all 9 policy rules
# Used to verify that valid configurations are not incorrectly rejected.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  # R-07: all three required tags present
  tags = {
    environment   = "dev"
    owner         = "team-platform"
    "cost-center" = "cc-001"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-compliant-dev"
  location = "swedencentral" # R-06: approved EU region
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

resource "azurerm_disk_encryption_set" "main" {
  name                = "des-compliant"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  key_vault_key_id    = "https://example-vault.vault.azure.net/keys/mykey/abc123"
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = "vm-compliant"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location # R-06: approved EU region
  size                  = "Standard_B1s"                        # R-01: allowed size
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.main.id]
  tags                  = local.tags # R-07: all required tags

  admin_ssh_key {
    username   = "adminuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC demo-key"
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

resource "azurerm_storage_account" "main" {
  name                      = "stcompliantdev001"
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location # R-06: approved EU region
  account_tier              = "Standard"                            # R-02: Standard only
  account_replication_type  = "LRS"
  allow_nested_items_to_be_public = false # R-03: no public blob access
  https_traffic_only_enabled      = true  # R-03: HTTPS enforced
  tags                      = local.tags # R-07: all required tags
}

resource "azurerm_role_assignment" "main" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader" # R-04: least-privilege role
  principal_id         = "00000000-0000-0000-0000-000000000000"
}

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

resource "azurerm_managed_disk" "main" {
  name                   = "disk-compliant"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location # R-06: approved EU region
  storage_account_type   = "Standard_LRS"
  create_option          = "Empty"
  disk_size_gb           = 64
  disk_encryption_set_id = azurerm_disk_encryption_set.main.id # R-08: encryption at rest
  tags                   = local.tags # R-07: all required tags
}

resource "azurerm_mssql_firewall_rule" "main" {
  name             = "sql-fw-office"
  server_id        = "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Sql/servers/mysqlserver"
  start_ip_address = "10.0.0.1"  # R-09: specific IP range only
  end_ip_address   = "10.0.0.10"
}

resource "azurerm_postgresql_firewall_rule" "main" {
  name                = "postgres-fw-office"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = "mypostgresserver"
  start_ip_address    = "10.0.0.1"  # R-09: specific IP range only
  end_ip_address      = "10.0.0.10"
}
