terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "s3" {}
}

provider "azurerm" {
  features {}
}

# --- Resource Group ---
resource "azurerm_resource_group" "lab7_rg" {
  name     = "Lab7-RG"
  location = "East US"
}

# ============================================================
# NETWORKING: VNet, Subnets, Route Tables
# ============================================================

resource "azurerm_virtual_network" "lab7_vnet" {
  name                = "Lab7-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab7_rg.location
  resource_group_name = azurerm_resource_group.lab7_rg.name

  tags = {
    Name = "Lab7-VNet"
  }
}

resource "azurerm_subnet" "lab7_public_subnet" {
  name                 = "Lab7-Public-Subnet"
  resource_group_name  = azurerm_resource_group.lab7_rg.name
  virtual_network_name = azurerm_virtual_network.lab7_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "lab7_private_subnet" {
  name                 = "Lab7-Private-Subnet"
  resource_group_name  = azurerm_resource_group.lab7_rg.name
  virtual_network_name = azurerm_virtual_network.lab7_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_route_table" "lab7_public_rt" {
  name                = "Lab7-Public-RT"
  location            = azurerm_resource_group.lab7_rg.location
  resource_group_name = azurerm_resource_group.lab7_rg.name

  route {
    name           = "Internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_route_table" "lab7_private_rt" {
  name                = "Lab7-Private-RT"
  location            = azurerm_resource_group.lab7_rg.location
  resource_group_name = azurerm_resource_group.lab7_rg.name
}

resource "azurerm_subnet_route_table_association" "lab7_public_rta" {
  subnet_id      = azurerm_subnet.lab7_public_subnet.id
  route_table_id = azurerm_route_table.lab7_public_rt.id
}

resource "azurerm_subnet_route_table_association" "lab7_private_rta" {
  subnet_id      = azurerm_subnet.lab7_private_subnet.id
  route_table_id = azurerm_route_table.lab7_private_rt.id
}
