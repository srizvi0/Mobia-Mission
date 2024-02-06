terraform {
  required_providers {
    azurerm = {
      version = "3.0.0"
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "RG1" {
  name     = "Resource_Group_1"
  location = var.location
}

resource "azurerm_virtual_network" "VNET1" {
  name                = "Virtual_Network_1"
  location            = azurerm_resource_group.RG1.location
  resource_group_name = azurerm_resource_group.RG1.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "SUB1" {
  resource_group_name    = azurerm_resource_group.RG1.name
  name                   = "subnet_1"
  virtual_network_name   = azurerm_virtual_network.VNET1.name
  depends_on             = [azurerm_virtual_network.VNET1]
  address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "NIC1" {
  name                      = "network_interface1"
  resource_group_name       = azurerm_resource_group.RG1.name
  location                  = azurerm_resource_group.RG1.location
  depends_on                = [azurerm_virtual_network.VNET1]

  ip_configuration {
    name                          = "ip_configuration1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.SUB1.id
  }
}

resource "azurerm_windows_virtual_machine" "VM1" {
  name                = "VM-1"
  resource_group_name = azurerm_resource_group.RG1.name
  location            = azurerm_resource_group.RG1.location
  size                = "Standard_F2"
  admin_username      = "VirtualMachine1"
  admin_password      = "VirtualMachinePass1"
  network_interface_ids = [
    azurerm_network_interface.NIC1.id,
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

resource "azurerm_kubernetes_cluster" "AKS1" {
  name                = "AKS-1"
  location            = "East US"
  resource_group_name = azurerm_resource_group.RG1.name
  dns_prefix          = "DNSAKS-1"

  default_node_pool {
    name       = "nodepool1"
    vm_size    = "Standard_F2"
    node_count = 1
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_container_registry" "ACR1" {
  name                = "ACRNEW125"
  location            = "East US"
  resource_group_name = azurerm_resource_group.RG1.name
  sku                 = "Basic"

  identity {
    type          = "UserAssigned"
    identity_ids  = [azurerm_user_assigned_identity.Identity1.id]
  }
}

resource "azurerm_user_assigned_identity" "Identity1" {
  name                = "AUSI"
  resource_group_name = azurerm_resource_group.RG1.name
  location            = "East US"
}

# Outputs for terraform resources


output "virtual_machine_public_ip" {
  value = azurerm_windows_virtual_machine.VM1.public_ip_address
}

output "kubernetes_cluster_id" {
  value = azurerm_kubernetes_cluster.AKS1.id
}

output "container_registry_login_server" {
  value = azurerm_container_registry.ACR1.login_server
}

output "user_assigned_identity_principal_id" {
  value = azurerm_user_assigned_identity.Identity1.principal_id
}
