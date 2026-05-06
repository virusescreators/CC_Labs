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

# ─── Resource Group ───────────────────────────────────────────────────────────

resource "azurerm_resource_group" "lab11_rg" {
  name     = "Lab11-RG-${random_id.suffix.hex}"
  location = "East US"
}

# ─── Networking ───────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "lab11_vnet" {
  name                = "HaseenUllah-22MDSWE238-Lab11-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab11_rg.location
  resource_group_name = azurerm_resource_group.lab11_rg.name

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab11-VNet"
  }
}

resource "azurerm_subnet" "lab11_subnet" {
  name                 = "Lab11-Subnet"
  resource_group_name  = azurerm_resource_group.lab11_rg.name
  virtual_network_name = azurerm_virtual_network.lab11_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "lab11_nsg" {
  name                = "Lab11-NSG"
  location            = azurerm_resource_group.lab11_rg.location
  resource_group_name = azurerm_resource_group.lab11_rg.name

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
    Name = "Lab11-NSG"
  }
}

resource "azurerm_subnet_network_security_group_association" "lab11_nsg_assoc" {
  subnet_id                 = azurerm_subnet.lab11_subnet.id
  network_security_group_id = azurerm_network_security_group.lab11_nsg.id
}

# ─── Application Gateway (Path-Based Routing on Azure) ───────────────────────
# Azure Application Gateway is the Azure equivalent of AWS ALB with path routing.
# It supports URL path-based routing rules and WAF capabilities.

resource "azurerm_subnet" "lab11_agw_subnet" {
  name                 = "Lab11-AGW-Subnet"
  resource_group_name  = azurerm_resource_group.lab11_rg.name
  virtual_network_name = azurerm_virtual_network.lab11_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "lab11_agw_pip" {
  name                = "Lab11-AGW-PIP"
  location            = azurerm_resource_group.lab11_rg.location
  resource_group_name = azurerm_resource_group.lab11_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

locals {
  frontend_ip_config_name = "appGwFrontendIPConfig"
  frontend_port_name      = "appGwFrontendPort"
  http_listener_name      = "appGwHttpListener"
  url_path_map_name       = "appGwUrlPathMap"

  app_backend_pool_name     = "appGwAppBackendPool"
  api_backend_pool_name     = "appGwApiBackendPool"
  app_backend_http_settings = "appGwAppBackendHttpSettings"
  api_backend_http_settings = "appGwApiBackendHttpSettings"

  default_routing_rule_name = "appGwDefaultRoutingRule"
}

resource "azurerm_application_gateway" "lab11_agw" {
  name                = "lab11-agw-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab11_rg.name
  location            = azurerm_resource_group.lab11_rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGwIpConfig"
    subnet_id = azurerm_subnet.lab11_agw_subnet.id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_config_name
    public_ip_address_id = azurerm_public_ip.lab11_agw_pip.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  # ── Backend Pools ────────────────────────────────────────────────────────────
  # App VMSS Backend Pool
  backend_address_pool {
    name = local.app_backend_pool_name
  }

  # API VMSS Backend Pool
  backend_address_pool {
    name = local.api_backend_pool_name
  }

  # ── HTTP Settings ─────────────────────────────────────────────────────────────
  backend_http_settings {
    name                  = local.app_backend_http_settings
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    path                  = "/app/"
    pick_host_name_from_backend_address = false
  }

  backend_http_settings {
    name                  = local.api_backend_http_settings
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    path                  = "/api/"
    pick_host_name_from_backend_address = false
  }

  # ── HTTP Listener ─────────────────────────────────────────────────────────────
  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_config_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  # ── URL Path Map (Path-Based Routing) ─────────────────────────────────────────
  url_path_map {
    name                               = local.url_path_map_name
    default_backend_address_pool_name  = local.app_backend_pool_name
    default_backend_http_settings_name = local.app_backend_http_settings

    path_rule {
      name                       = "AppPathRule"
      paths                      = ["/app/*"]
      backend_address_pool_name  = local.app_backend_pool_name
      backend_http_settings_name = local.app_backend_http_settings
    }

    path_rule {
      name                       = "ApiPathRule"
      paths                      = ["/api/*"]
      backend_address_pool_name  = local.api_backend_pool_name
      backend_http_settings_name = local.api_backend_http_settings
    }
  }

  # ── Routing Rule ──────────────────────────────────────────────────────────────
  request_routing_rule {
    name               = local.default_routing_rule_name
    rule_type          = "PathBasedRouting"
    http_listener_name = local.http_listener_name
    url_path_map_name  = local.url_path_map_name
    priority           = 10
  }

  tags = {
    Name = "Lab11-AGW"
  }
}

# ─── SSH Key ──────────────────────────────────────────────────────────────────

resource "tls_private_key" "lab11_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ─── Frontend App VMSS ────────────────────────────────────────────────────────

resource "azurerm_linux_virtual_machine_scale_set" "lab11_vmss_app" {
  name                = "lab11-vmss-app-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab11_rg.name
  location            = azurerm_resource_group.lab11_rg.location
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.lab11_key.public_key_openssh
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
    name    = "lab11-app-nic"
    primary = true

    ip_configuration {
      name                                         = "internal"
      primary                                      = true
      subnet_id                                    = azurerm_subnet.lab11_subnet.id
      application_gateway_backend_address_pool_ids = [
        tolist(azurerm_application_gateway.lab11_agw.backend_address_pool).0.id
      ]
    }
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    mkdir -p /var/www/html/app
    cat > /var/www/html/app/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head><title>Lab 11 - Frontend App (Azure)</title></head>
    <body style="font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;text-align:center;padding:50px;">
      <h1 style="color:#0f3460;">&#128196; Frontend App (Azure)</h1>
      <p>Path: <strong>/app/</strong></p>
      <p>Scale Set: <strong>App VMSS</strong></p>
    </body>
    </html>
    HTML
  EOF
  )

  tags = {
    Name = "Lab11-App-VMSS"
  }
}

# ─── Backend API VMSS ─────────────────────────────────────────────────────────

resource "azurerm_linux_virtual_machine_scale_set" "lab11_vmss_api" {
  name                = "lab11-vmss-api-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab11_rg.name
  location            = azurerm_resource_group.lab11_rg.location
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.lab11_key.public_key_openssh
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
    name    = "lab11-api-nic"
    primary = true

    ip_configuration {
      name                                         = "internal"
      primary                                      = true
      subnet_id                                    = azurerm_subnet.lab11_subnet.id
      application_gateway_backend_address_pool_ids = [
        tolist(azurerm_application_gateway.lab11_agw.backend_address_pool).1.id
      ]
    }
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    mkdir -p /var/www/html/api
    cat > /var/www/html/api/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head><title>Lab 11 - Backend API (Azure)</title></head>
    <body style="font-family:sans-serif;background:#0a0a0a;color:#e0e0e0;text-align:center;padding:50px;">
      <h1 style="color:#e94560;">&#128196; Backend API (Azure)</h1>
      <p>Path: <strong>/api/</strong></p>
      <p>Scale Set: <strong>API VMSS</strong></p>
    </body>
    </html>
    HTML
  EOF
  )

  tags = {
    Name = "Lab11-Api-VMSS"
  }
}
