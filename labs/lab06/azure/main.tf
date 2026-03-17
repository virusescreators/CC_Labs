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
resource "azurerm_resource_group" "lab6_rg" {
  name     = "Lab6-RG"
  location = "East US"
}

# ============================================================
# NETWORKING: VNet, Subnet, Public IP, NSG
# ============================================================

resource "azurerm_virtual_network" "lab6_vnet" {
  name                = "Lab6-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab6_rg.location
  resource_group_name = azurerm_resource_group.lab6_rg.name

  tags = {
    Name = "Lab6-VNet"
  }
}

resource "azurerm_subnet" "lab6_subnet" {
  name                 = "Lab6-Subnet"
  resource_group_name  = azurerm_resource_group.lab6_rg.name
  virtual_network_name = azurerm_virtual_network.lab6_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "lab6_public_ip" {
  name                = "Lab6-PublicIP"
  resource_group_name = azurerm_resource_group.lab6_rg.name
  location            = azurerm_resource_group.lab6_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "Lab6-PublicIP"
  }
}

# ============================================================
# SECURITY: Network Security Group — Allow SSH (22) + HTTP (80)
# ============================================================

resource "azurerm_network_security_group" "lab6_nsg" {
  name                = "Lab6-NSG"
  location            = azurerm_resource_group.lab6_rg.location
  resource_group_name = azurerm_resource_group.lab6_rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" # Lab only — restrict in production
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
    Name = "Lab6-NSG"
  }
}

# ============================================================
# NETWORK INTERFACE
# ============================================================

resource "azurerm_network_interface" "lab6_nic" {
  name                = "Lab6-NIC"
  location            = azurerm_resource_group.lab6_rg.location
  resource_group_name = azurerm_resource_group.lab6_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab6_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab6_public_ip.id
  }

  tags = {
    Name = "Lab6-NIC"
  }
}

resource "azurerm_network_interface_security_group_association" "lab6_nic_nsg" {
  network_interface_id      = azurerm_network_interface.lab6_nic.id
  network_security_group_id = azurerm_network_security_group.lab6_nsg.id
}

# ============================================================
# KEY PAIR: Auto-generated TLS key for SSH access
# ============================================================

resource "tls_private_key" "lab6_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ============================================================
# TASK 1: Launch a Linux Virtual Machine
# ============================================================
# Free Tier eligible: Standard_B1s, Ubuntu 22.04 LTS
# custom_data installs Apache2 and serves a student info HTML page

resource "azurerm_linux_virtual_machine" "lab6_vm" {
  name                = "lab6-vm-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab6_rg.name
  location            = azurerm_resource_group.lab6_rg.location
  size                = "Standard_B1s" # Free Tier eligible (750 hrs/mo, 12 months)

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.lab6_key.public_key_openssh
  }

  network_interface_ids = [azurerm_network_interface.lab6_nic.id]

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

  # ============================================================
  # TASK 2 & 3: Install Apache and serve student HTML page
  # ============================================================
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
        <title>Lab 6 - Azure VM Web Server</title>
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
            <p class="reg">Registration # XXXX-XXXX</p>
            <div class="info">
                <p>Cloud Computing — Lab 6</p>
                <p>Azure Virtual Machine Web Server</p>
                <p>Size: Standard_B1s &bull; OS: Ubuntu 22.04 LTS</p>
            </div>
            <span class="badge">Served from Azure VM &#x2601;</span>
        </div>
    </body>
    </html>
    HTML
  EOF
  )

  tags = {
    Name = "Lab6-VM"
  }
}

# ============================================================
# TASK 4: Connect via SSH
# ============================================================
# After deploying, connect using:
#
#   Save the private key:
#     terraform output -raw private_key > lab6-key.pem
#     chmod 400 lab6-key.pem   (Linux/Mac)
#
#   SSH into the VM:
#     ssh -i lab6-key.pem azureuser@<public_ip>
#
#   For Windows (PuTTY):
#     1. Convert the PEM to PPK using PuTTYgen
#     2. Open PuTTY → enter the public IP
#     3. Go to Connection → SSH → Auth → Browse for the PPK file
#     4. Click Open → login as: azureuser
#
# ============================================================
# TASK 5: Verify Web Server
# ============================================================
# Open the public IP in your browser:
#   http://<public_ip>
#
# You should see the student info HTML page.
#
# ============================================================
# IMPORTANT: Delete resources after lab to avoid billing
# ============================================================
# Run: Actions → Deploy Labs → Lab 6 → azure → destroy
