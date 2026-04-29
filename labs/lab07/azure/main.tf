terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "random_id" "suffix" {
  byte_length = 4
}

# --- Resource Group ---
resource "azurerm_resource_group" "lab7_rg" {
  name     = "Lab7-RG"
  location = "East US"
}

# ============================================================
# TASK 1: Create a Custom Virtual Network (Student Name + Roll Number)
# ============================================================

resource "azurerm_virtual_network" "lab7_vnet" {
  name                = "HaseenUllah-22MDSWE238-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab7_rg.location
  resource_group_name = azurerm_resource_group.lab7_rg.name

  tags = {
    Name = "HaseenUllah-22MDSWE238-VNet"
  }
}

# ============================================================
# TASK 2: Create Public and Private Subnets
# ============================================================

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

# ============================================================
# TASK 4: Route Tables for Public and Private Subnets
# ============================================================

# --- Public Route Table ---
resource "azurerm_route_table" "lab7_public_rt" {
  name                = "Lab7-Public-RT"
  location            = azurerm_resource_group.lab7_rg.location
  resource_group_name = azurerm_resource_group.lab7_rg.name

  route {
    name                   = "InternetRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
  }

  tags = {
    Name = "Lab7-Public-RT"
  }
}

resource "azurerm_subnet_route_table_association" "lab7_public_rta" {
  subnet_id      = azurerm_subnet.lab7_public_subnet.id
  route_table_id = azurerm_route_table.lab7_public_rt.id
}

# --- Private Route Table ---
resource "azurerm_route_table" "lab7_private_rt" {
  name                = "Lab7-Private-RT"
  location            = azurerm_resource_group.lab7_rg.location
  resource_group_name = azurerm_resource_group.lab7_rg.name

  route {
    name                   = "DenyInternet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "None"
  }

  tags = {
    Name = "Lab7-Private-RT"
  }
}

resource "azurerm_subnet_route_table_association" "lab7_private_rta" {
  subnet_id      = azurerm_subnet.lab7_private_subnet.id
  route_table_id = azurerm_route_table.lab7_private_rt.id
}

# ============================================================
# SECURITY: Network Security Groups for Public and Private Subnets
# ============================================================

resource "azurerm_network_security_group" "lab7_public_nsg" {
  name                = "Lab7-Public-NSG"
  location            = azurerm_resource_group.lab7_rg.location
  resource_group_name = azurerm_resource_group.lab7_rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "Lab7-Public-NSG"
  }
}

resource "azurerm_network_security_group" "lab7_private_nsg" {
  name                = "Lab7-Private-NSG"
  location            = azurerm_resource_group.lab7_rg.location
  resource_group_name = azurerm_resource_group.lab7_rg.name

  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "Lab7-Private-NSG"
  }
}

resource "azurerm_subnet_network_security_group_association" "lab7_public_nsg_assoc" {
  subnet_id                 = azurerm_subnet.lab7_public_subnet.id
  network_security_group_id = azurerm_network_security_group.lab7_public_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "lab7_private_nsg_assoc" {
  subnet_id                 = azurerm_subnet.lab7_private_subnet.id
  network_security_group_id = azurerm_network_security_group.lab7_private_nsg.id
}

# ============================================================
# IMPORTANT: Destroy resources after lab to avoid billing
# ============================================================
# Run: Actions → Deploy Labs → Lab 7 → azure → destroy
