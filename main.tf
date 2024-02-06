terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = "Resource_Group_1"
  location = var.location
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "Virtual_Network_1"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                   = "subnet_1"
  resource_group_name    = azurerm_resource_group.resource_group.name
  virtual_network_name   = azurerm_virtual_network.virtual_network.name
  depends_on             = [azurerm_virtual_network.virtual_network]
  address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "network_interface" {
  name                      = "network_interface_1"
  resource_group_name       = azurerm_resource_group.resource_group.name
  location                  = azurerm_resource_group.resource_group.location
  depends_on                = [azurerm_virtual_network.virtual_network]

  ip_configuration {
    name                          = "ip_configuration_1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet.id
  }
}

resource "azurerm_windows_virtual_machine" "virtual_machine" {
  name                = "vm-1"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_F2"
  admin_username      = "VirtualMachine1"
  admin_password      = "VirtualMachinePass1"
  network_interface_ids = [
    azurerm_network_interface.network_interface.id,
  ]
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
  name                = "Cluster_1"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = "East US"
  dns_prefix          = "DNSAKS-1"

  default_node_pool {
    name       = "defaultnp"
    vm_size    = "Standard_F2"
    node_count = 1
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_container_registry" "container_registry" {
  name                = "ACRNew12"
  location            = "East US"
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Basic"

  identity {
    type          = "UserAssigned"
    identity_ids  = [azurerm_user_assigned_identity.Identity1.id]
  }
}

resource "azurerm_user_assigned_identity" "Identity1" {
  name                = "Identity_1"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = "East US"
}

# Outputs for terraform resources

output "virtual_machine_public_ip" {
  value = azurerm_windows_virtual_machine.virtual_machine.public_ip_address
}

output "kubernetes_cluster_id" {
  value = azurerm_kubernetes_cluster.kubernetes_cluster.id
}

output "container_registry_login_server" {
  value = azurerm_container_registry.container_registry.login_server
}

output "user_assigned_identity_principal_id" {
  value = azurerm_user_assigned_identity.Identity1.principal_id
}
