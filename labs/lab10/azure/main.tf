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
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "azurerm_resource_group" "lab10_rg" {
  name     = "Lab10-RG-${random_id.suffix.hex}"
  location = "East US"
}

resource "azurerm_virtual_network" "lab10_vnet" {
  name                = "HaseenUllah-22MDSWE238-Lab10-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab10_rg.location
  resource_group_name = azurerm_resource_group.lab10_rg.name

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab10-VNet"
  }
}

resource "azurerm_subnet" "lab10_subnet" {
  name                 = "Lab10-Subnet"
  resource_group_name  = azurerm_resource_group.lab10_rg.name
  virtual_network_name = azurerm_virtual_network.lab10_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "lab10_nsg" {
  name                = "Lab10-NSG"
  location            = azurerm_resource_group.lab10_rg.location
  resource_group_name = azurerm_resource_group.lab10_rg.name

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
    name                       = "AllowLBHealthProbe"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "Lab10-NSG"
  }
}

resource "azurerm_subnet_network_security_group_association" "lab10_nsg_assoc" {
  subnet_id                 = azurerm_subnet.lab10_subnet.id
  network_security_group_id = azurerm_network_security_group.lab10_nsg.id
}

resource "azurerm_public_ip" "lab10_lb_pip" {
  name                = "Lab10-LB-PIP"
  location            = azurerm_resource_group.lab10_rg.location
  resource_group_name = azurerm_resource_group.lab10_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lab10_lb" {
  name                = "Lab10-LB"
  location            = azurerm_resource_group.lab10_rg.location
  resource_group_name = azurerm_resource_group.lab10_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lab10_lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lab10_pool" {
  loadbalancer_id = azurerm_lb.lab10_lb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "lab10_probe" {
  loadbalancer_id = azurerm_lb.lab10_lb.id
  name            = "HTTP-Probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/"
}

resource "azurerm_lb_rule" "lab10_rule" {
  loadbalancer_id                = azurerm_lb.lab10_lb.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lab10_pool.id]
  probe_id                       = azurerm_lb_probe.lab10_probe.id
  disable_outbound_snat          = true
}

resource "azurerm_lb_outbound_rule" "lab10_outbound" {
  name                    = "OutboundRule"
  loadbalancer_id         = azurerm_lb.lab10_lb.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lab10_pool.id

  frontend_ip_configuration {
    name = "PublicIPAddress"
  }
}

resource "tls_private_key" "lab10_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine_scale_set" "lab10_vmss" {
  name                = "lab10-vmss-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab10_rg.name
  location            = azurerm_resource_group.lab10_rg.location
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.lab10_key.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "lab10-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.lab10_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lab10_pool.id]
    }
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>Lab 10 - Azure VMSS Instance</h1><p>Served from VM Scale Set</p>" > /var/www/html/index.html
  EOF
  )
}
