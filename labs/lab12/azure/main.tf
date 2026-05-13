terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_id" "suffix" {
  byte_length = 4
}

# ─── Resource Group ───────────────────────────────────────────────────────────

resource "azurerm_resource_group" "lab12_rg" {
  name     = "Lab12-RG-${random_id.suffix.hex}"
  location = "East US"
}

# ─── Networking ───────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "lab12_vnet" {
  name                = "HaseenUllah-22MDSWE238-Lab12-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab12_rg.location
  resource_group_name = azurerm_resource_group.lab12_rg.name

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab12-VNet"
  }
}

resource "azurerm_subnet" "lab12_subnet" {
  name                 = "Lab12-Subnet"
  resource_group_name  = azurerm_resource_group.lab12_rg.name
  virtual_network_name = azurerm_virtual_network.lab12_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "lab12_pip" {
  name                = "Lab12-PIP"
  location            = azurerm_resource_group.lab12_rg.location
  resource_group_name = azurerm_resource_group.lab12_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "lab12_nsg" {
  name                = "Lab12-NSG"
  location            = azurerm_resource_group.lab12_rg.location
  resource_group_name = azurerm_resource_group.lab12_rg.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "Lab12-NSG"
  }
}

resource "azurerm_subnet_network_security_group_association" "lab12_nsg_assoc" {
  subnet_id                 = azurerm_subnet.lab12_subnet.id
  network_security_group_id = azurerm_network_security_group.lab12_nsg.id
}

resource "azurerm_network_interface" "lab12_nic" {
  name                = "Lab12-NIC"
  location            = azurerm_resource_group.lab12_rg.location
  resource_group_name = azurerm_resource_group.lab12_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab12_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab12_pip.id
  }
}

# ─── SSH Key ──────────────────────────────────────────────────────────────────

resource "tls_private_key" "lab12_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ─── Virtual Machine ──────────────────────────────────────────────────────────

resource "azurerm_linux_virtual_machine" "lab12_vm" {
  name                = "Lab12-VM"
  resource_group_name = azurerm_resource_group.lab12_rg.name
  location            = azurerm_resource_group.lab12_rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.lab12_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.lab12_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    # Update and install dependencies
    apt-get update -y
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs git nginx

    # Set up simple React application
    cd /home/azureuser
    npx create-react-app@latest react-app
    cd react-app
    npm run build

    # Configure Nginx to serve the React app
    rm -rf /var/www/html/*
    cp -r build/* /var/www/html/

    # Start Nginx
    systemctl start nginx
    systemctl enable nginx
  EOF
  )

  tags = {
    Name = "Lab12-React-App-VM"
  }
}
