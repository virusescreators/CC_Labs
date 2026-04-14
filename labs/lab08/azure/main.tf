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
  backend "s3" {}
}

provider "azurerm" {
  features {}
}

resource "random_id" "suffix" {
  byte_length = 4
}

# --- Resource Group ---
resource "azurerm_resource_group" "lab8_rg" {
  name     = "Lab8-RG"
  location = "East US"
}

# ============================================================
# TASK 1: Create VNet with Public & Private Subnets
# ============================================================

resource "azurerm_virtual_network" "lab8_vnet" {
  name                = "HaseenUllah-22MDSWE238-Lab8-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab8_rg.location
  resource_group_name = azurerm_resource_group.lab8_rg.name

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab8-VNet"
  }
}

# --- Public Subnet ---
resource "azurerm_subnet" "lab8_public_subnet" {
  name                 = "Lab8-Public-Subnet"
  resource_group_name  = azurerm_resource_group.lab8_rg.name
  virtual_network_name = azurerm_virtual_network.lab8_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# --- Private Subnet ---
resource "azurerm_subnet" "lab8_private_subnet" {
  name                 = "Lab8-Private-Subnet"
  resource_group_name  = azurerm_resource_group.lab8_rg.name
  virtual_network_name = azurerm_virtual_network.lab8_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# ============================================================
# TASK 1 (cont.): Route Tables
# ============================================================

# --- Public Route Table ---
resource "azurerm_route_table" "lab8_public_rt" {
  name                = "Lab8-Public-RT"
  location            = azurerm_resource_group.lab8_rg.location
  resource_group_name = azurerm_resource_group.lab8_rg.name

  route {
    name                   = "InternetRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
  }

  tags = {
    Name = "Lab8-Public-RT"
  }
}

resource "azurerm_subnet_route_table_association" "lab8_public_rta" {
  subnet_id      = azurerm_subnet.lab8_public_subnet.id
  route_table_id = azurerm_route_table.lab8_public_rt.id
}

# --- Private Route Table ---
# Drops internet traffic to keep private subnet isolated
resource "azurerm_route_table" "lab8_private_rt" {
  name                = "Lab8-Private-RT"
  location            = azurerm_resource_group.lab8_rg.location
  resource_group_name = azurerm_resource_group.lab8_rg.name

  route {
    name                   = "DenyInternet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "None"
  }

  tags = {
    Name = "Lab8-Private-RT"
  }
}

resource "azurerm_subnet_route_table_association" "lab8_private_rta" {
  subnet_id      = azurerm_subnet.lab8_private_subnet.id
  route_table_id = azurerm_route_table.lab8_private_rt.id
}

# ============================================================
# NETWORK SECURITY GROUPS
# ============================================================

# --- Public NSG ---
# Allows SSH (22), HTTP (80), and ICMP from the internet
resource "azurerm_network_security_group" "lab8_public_nsg" {
  name                = "Lab8-Public-NSG"
  location            = azurerm_resource_group.lab8_rg.location
  resource_group_name = azurerm_resource_group.lab8_rg.name

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

  security_rule {
    name                       = "AllowICMP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "Lab8-Public-NSG"
  }
}

# --- Private NSG ---
# ONLY allows SSH and ICMP from the public subnet (10.0.1.0/24)
# Denies all internet inbound traffic
resource "azurerm_network_security_group" "lab8_private_nsg" {
  name                = "Lab8-Private-NSG"
  location            = azurerm_resource_group.lab8_rg.location
  resource_group_name = azurerm_resource_group.lab8_rg.name

  security_rule {
    name                       = "AllowSSHFromPublicSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24" # Public subnet CIDR only
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowICMPFromPublicSubnet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24" # Public subnet CIDR only
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 120
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
    Name = "Lab8-Private-NSG"
  }
}

# --- NSG Subnet Associations ---
resource "azurerm_subnet_network_security_group_association" "lab8_public_nsg_assoc" {
  subnet_id                 = azurerm_subnet.lab8_public_subnet.id
  network_security_group_id = azurerm_network_security_group.lab8_public_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "lab8_private_nsg_assoc" {
  subnet_id                 = azurerm_subnet.lab8_private_subnet.id
  network_security_group_id = azurerm_network_security_group.lab8_private_nsg.id
}

# ============================================================
# KEY PAIR: Auto-generated TLS key for SSH access
# ============================================================

resource "tls_private_key" "lab8_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ============================================================
# PUBLIC IP: For the public VM only
# ============================================================

resource "azurerm_public_ip" "lab8_public_ip" {
  name                = "Lab8-PublicIP"
  resource_group_name = azurerm_resource_group.lab8_rg.name
  location            = azurerm_resource_group.lab8_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "Lab8-PublicIP"
  }
}

# ============================================================
# NETWORK INTERFACES
# ============================================================

# --- Public VM NIC ---
resource "azurerm_network_interface" "lab8_public_nic" {
  name                = "Lab8-Public-NIC"
  location            = azurerm_resource_group.lab8_rg.location
  resource_group_name = azurerm_resource_group.lab8_rg.name

  ip_configuration {
    name                          = "public-ip-config"
    subnet_id                     = azurerm_subnet.lab8_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab8_public_ip.id
  }

  tags = {
    Name = "Lab8-Public-NIC"
  }
}

resource "azurerm_network_interface_security_group_association" "lab8_public_nic_nsg" {
  network_interface_id      = azurerm_network_interface.lab8_public_nic.id
  network_security_group_id = azurerm_network_security_group.lab8_public_nsg.id
}

# --- Private VM NIC ---
# No public IP assigned
resource "azurerm_network_interface" "lab8_private_nic" {
  name                = "Lab8-Private-NIC"
  location            = azurerm_resource_group.lab8_rg.location
  resource_group_name = azurerm_resource_group.lab8_rg.name

  ip_configuration {
    name                          = "private-ip-config"
    subnet_id                     = azurerm_subnet.lab8_private_subnet.id
    private_ip_address_allocation = "Dynamic"
    # No public IP — private instance
  }

  tags = {
    Name = "Lab8-Private-NIC"
  }
}

resource "azurerm_network_interface_security_group_association" "lab8_private_nic_nsg" {
  network_interface_id      = azurerm_network_interface.lab8_private_nic.id
  network_security_group_id = azurerm_network_security_group.lab8_private_nsg.id
}

# ============================================================
# TASK 2: Launch Public VM (Bastion / Jump Host)
# ============================================================
# Free Tier eligible: Standard_B1s, Ubuntu 22.04 LTS
# custom_data installs Apache2 and serves a student info HTML page

resource "azurerm_linux_virtual_machine" "lab8_public_vm" {
  name                = "lab8-public-vm-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab8_rg.name
  location            = azurerm_resource_group.lab8_rg.location
  size                = "Standard_B1s" # Free Tier eligible (750 hrs/mo, 12 months)

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.lab8_key.public_key_openssh
  }

  network_interface_ids = [azurerm_network_interface.lab8_public_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
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

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Lab 8 - Public Azure VM</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
                background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
                color: #fff;
            }
            .card {
                background: rgba(255, 255, 255, 0.08);
                backdrop-filter: blur(12px);
                border: 1px solid rgba(255, 255, 255, 0.15);
                border-radius: 20px;
                padding: 3rem 4rem;
                text-align: center;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
            }
            h1 { font-size: 2.2rem; margin-bottom: 0.5rem; }
            .reg { font-size: 1.1rem; color: #a78bfa; margin-bottom: 1.5rem; }
            .info { font-size: 0.95rem; color: #cbd5e1; line-height: 1.8; }
            .badge {
                display: inline-block;
                margin-top: 1.5rem;
                padding: 0.4rem 1.2rem;
                background: linear-gradient(90deg, #0078d4, #50a3e8);
                border-radius: 999px;
                font-size: 0.85rem;
                font-weight: 600;
            }
        </style>
    </head>
    <body>
        <div class="card">
            <h1>Haseen Ullah</h1>
            <p class="reg">Registration # 22MDSWE238</p>
            <div class="info">
                <p>Cloud Computing — Lab 8</p>
                <p>Public Azure VM (Bastion Host)</p>
                <p>Subnet: Public (10.0.1.0/24) &bull; Size: Standard_B1s</p>
            </div>
            <span class="badge">Public Subnet &#x2601;</span>
        </div>
    </body>
    </html>
    HTML
  EOF
  )

  tags = {
    Name = "Lab8-Public-VM"
  }
}

# ============================================================
# TASK 3: Launch Private VM
# ============================================================
# Launched in the private subnet WITHOUT a public IP.
# Accessible ONLY from the public VM via SSH / ping.

resource "azurerm_linux_virtual_machine" "lab8_private_vm" {
  name                = "lab8-private-vm-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab8_rg.name
  location            = azurerm_resource_group.lab8_rg.location
  size                = "Standard_B1s"

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.lab8_key.public_key_openssh
  }

  network_interface_ids = [azurerm_network_interface.lab8_private_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    Name = "Lab8-Private-VM"
  }
}

# ============================================================
# TASK 4 & 5: Access Verification
# ============================================================
# Steps to verify:
#
# 1. Save the private key:
#      terraform output -raw private_key > lab8-key.pem
#      chmod 400 lab8-key.pem   (Linux/Mac)
#
# 2. SSH into the PUBLIC VM:
#      ssh -i lab8-key.pem azureuser@<public_vm_public_ip>
#
# 3. From the PUBLIC VM, copy the key and SSH into PRIVATE:
#      scp -i lab8-key.pem lab8-key.pem azureuser@<public_ip>:~/
#      # On public VM:
#      chmod 400 lab8-key.pem
#      ssh -i lab8-key.pem azureuser@<private_vm_private_ip>
#
# 4. Ping the private VM from the public VM:
#      ping <private_vm_private_ip>
#      (Should SUCCEED — allowed by NSG)
#
# 5. Try pinging the private VM from outside the VNet:
#      (Should FAIL — no public IP, internet denied)
#
# For Windows (PuTTY):
#   1. Convert PEM to PPK using PuTTYgen
#   2. PuTTY → enter public IP → Connection → SSH → Auth → PPK
#   3. Login as: azureuser
#   4. From public VM, ping private IP
#
# ============================================================
# IMPORTANT: Delete resources after lab to avoid billing
# ============================================================
# Run: Actions → Deploy Labs → Lab 8 → azure → destroy
