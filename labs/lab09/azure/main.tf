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

# ============================================================
# RESOURCE GROUP & VNET
# ============================================================

resource "azurerm_resource_group" "lab9_rg" {
  name     = "Lab9-RG-${random_id.suffix.hex}"
  location = "East US"
}

resource "azurerm_virtual_network" "lab9_vnet" {
  name                = "HaseenUllah-22MDSWE238-Lab9-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab9_rg.location
  resource_group_name = azurerm_resource_group.lab9_rg.name

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab9-VNet"
  }
}

resource "azurerm_subnet" "lab9_subnet_1" {
  name                 = "Lab9-Subnet-1"
  resource_group_name  = azurerm_resource_group.lab9_rg.name
  virtual_network_name = azurerm_virtual_network.lab9_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "lab9_subnet_2" {
  name                 = "Lab9-Subnet-2"
  resource_group_name  = azurerm_resource_group.lab9_rg.name
  virtual_network_name = azurerm_virtual_network.lab9_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# ============================================================
# NETWORK SECURITY GROUP
# ============================================================

resource "azurerm_network_security_group" "lab9_nsg" {
  name                = "Lab9-NSG"
  location            = azurerm_resource_group.lab9_rg.location
  resource_group_name = azurerm_resource_group.lab9_rg.name

  # Allow HTTP from the internet (Client IP is preserved by the Load Balancer)
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

  # Allow the Load Balancer Health Probe
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
    Name = "Lab9-NSG"
  }
}

resource "azurerm_subnet_network_security_group_association" "lab9_nsg_assoc_1" {
  subnet_id                 = azurerm_subnet.lab9_subnet_1.id
  network_security_group_id = azurerm_network_security_group.lab9_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "lab9_nsg_assoc_2" {
  subnet_id                 = azurerm_subnet.lab9_subnet_2.id
  network_security_group_id = azurerm_network_security_group.lab9_nsg.id
}

# ============================================================
# LOAD BALANCER
# ============================================================

resource "azurerm_public_ip" "lab9_lb_pip" {
  name                = "Lab9-LB-PIP"
  location            = azurerm_resource_group.lab9_rg.location
  resource_group_name = azurerm_resource_group.lab9_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lab9_lb" {
  name                = "Lab9-LB"
  location            = azurerm_resource_group.lab9_rg.location
  resource_group_name = azurerm_resource_group.lab9_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lab9_lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lab9_pool" {
  loadbalancer_id = azurerm_lb.lab9_lb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "lab9_probe" {
  loadbalancer_id = azurerm_lb.lab9_lb.id
  name            = "HTTP-Probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/"
}

resource "azurerm_lb_rule" "lab9_rule" {
  loadbalancer_id                = azurerm_lb.lab9_lb.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lab9_pool.id]
  probe_id                       = azurerm_lb_probe.lab9_probe.id
  disable_outbound_snat          = true
}

resource "azurerm_lb_outbound_rule" "lab9_outbound" {
  name                    = "OutboundRule"
  loadbalancer_id         = azurerm_lb.lab9_lb.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lab9_pool.id

  frontend_ip_configuration {
    name = "PublicIPAddress"
  }
}

# ============================================================
# VIRTUAL MACHINES
# ============================================================

resource "azurerm_network_interface" "lab9_nic_1" {
  name                = "Lab9-NIC-1"
  location            = azurerm_resource_group.lab9_rg.location
  resource_group_name = azurerm_resource_group.lab9_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab9_subnet_1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "lab9_nic_2" {
  name                = "Lab9-NIC-2"
  location            = azurerm_resource_group.lab9_rg.location
  resource_group_name = azurerm_resource_group.lab9_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab9_subnet_2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "lab9_nic_1_assoc" {
  network_interface_id    = azurerm_network_interface.lab9_nic_1.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lab9_pool.id
}

resource "azurerm_network_interface_backend_address_pool_association" "lab9_nic_2_assoc" {
  network_interface_id    = azurerm_network_interface.lab9_nic_2.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lab9_pool.id
}

resource "tls_private_key" "lab9_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "lab9_vm_1" {
  name                = "lab9-vm-1-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab9_rg.name
  location            = azurerm_resource_group.lab9_rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.lab9_nic_1.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.lab9_key.public_key_openssh
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
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>Lab 9 - Azure VM A</h1><p>Served from Subnet 1</p>" > /var/www/html/index.html
  EOF
  )
}

resource "azurerm_linux_virtual_machine" "lab9_vm_2" {
  name                = "lab9-vm-2-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab9_rg.name
  location            = azurerm_resource_group.lab9_rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.lab9_nic_2.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.lab9_key.public_key_openssh
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
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>Lab 9 - Azure VM B</h1><p>Served from Subnet 2</p>" > /var/www/html/index.html
  EOF
  )
}
