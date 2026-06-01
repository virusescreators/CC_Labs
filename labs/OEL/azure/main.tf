terraform {
  backend "s3" {
    bucket         = "tfstate-haseen-22mdswe238"
    key            = "OEL/azure/terraform.tfstate"
    region         = "us-east-1"
  }

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

resource "azurerm_resource_group" "oel_rg" {
  name     = "OEL-Portfolio-RG-${random_id.suffix.hex}"
  location = "East US"
}

# ─── Storage Account & Public Assets (Part 3 Equivalent) ──────────────────────

resource "azurerm_storage_account" "portfolio_storage" {
  name                     = "oelportfolio${random_id.suffix.hex}" # Lowercase & numbers only, max 24 chars
  resource_group_name      = azurerm_resource_group.oel_rg.name
  location                 = azurerm_resource_group.oel_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  # Enable public network access so assets can be read
  public_network_access_enabled = true
}

# Blob container set to public blob-level access
resource "azurerm_storage_container" "assets_container" {
  name                  = "assets"
  storage_account_name  = azurerm_storage_account.portfolio_storage.name
  container_access_type = "blob"
}

# Upload dummy CV/Resume and project documentation as blobs
resource "azurerm_storage_blob" "resume" {
  name                   = "resume.pdf"
  storage_account_name   = azurerm_storage_account.portfolio_storage.name
  storage_container_name = azurerm_storage_container.assets_container.name
  type                   = "Block"
  source_content         = "Haseen Ullah (22MDSWE238) - Professional CV / Resume\nCourse: SE-409L Cloud Computing Lab\nEmail: haseen.ullah@student.example.com\nSkills: Azure Administration, Terraform, AWS DevOps, CI/CD, Linux Systems."
  content_type           = "application/pdf"
}

resource "azurerm_storage_blob" "project_doc" {
  name                   = "project_doc.txt"
  storage_account_name   = azurerm_storage_account.portfolio_storage.name
  storage_container_name = azurerm_storage_container.assets_container.name
  type                   = "Block"
  source_content         = "Project Documentation Summary:\n1. AI-Driven Threat Detection: Deployed real-time log anomaly detectors via SageMaker.\n2. Cloud-Native E-Commerce: Scaled dynamic catalogs using AWS EC2, ALB, and Auto Scaling.\n3. Serverless Task Orchestrator: Built microservices using Lambda, API Gateway, and DynamoDB."
  content_type           = "text/plain"
}

# ─── Networking ───────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "oel_vnet" {
  name                = "HaseenUllah-22MDSWE238-OEL-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.oel_rg.location
  resource_group_name = azurerm_resource_group.oel_rg.name

  tags = {
    Name = "HaseenUllah-22MDSWE238-OEL-VNet"
  }
}

resource "azurerm_subnet" "oel_subnet" {
  name                 = "OEL-Subnet"
  resource_group_name  = azurerm_resource_group.oel_rg.name
  virtual_network_name = azurerm_virtual_network.oel_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "oel_pip" {
  name                = "OEL-PIP"
  location            = azurerm_resource_group.oel_rg.location
  resource_group_name = azurerm_resource_group.oel_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "oel_nsg" {
  name                = "OEL-NSG"
  location            = azurerm_resource_group.oel_rg.location
  resource_group_name = azurerm_resource_group.oel_rg.name

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
}

resource "azurerm_subnet_network_security_group_association" "oel_nsg_assoc" {
  subnet_id                 = azurerm_subnet.oel_subnet.id
  network_security_group_id = azurerm_network_security_group.oel_nsg.id
}

# ─── Public Load Balancer (Part 4 Option A/B Equivalent) ──────────────────────

resource "azurerm_lb" "oel_lb" {
  name                = "OEL-LB"
  location            = azurerm_resource_group.oel_rg.location
  resource_group_name = azurerm_resource_group.oel_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.oel_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "oel_bap" {
  loadbalancer_id = azurerm_lb.oel_lb.id
  name            = "OEL-BackEndAddressPool"
}

resource "azurerm_lb_probe" "oel_probe" {
  loadbalancer_id = azurerm_lb.oel_lb.id
  name            = "http-running-probe"
  port            = 80
  request_path    = "/"
}

resource "azurerm_lb_rule" "oel_lb_rule" {
  loadbalancer_id                = azurerm_lb.oel_lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.oel_bap.id]
  probe_id                       = azurerm_lb_probe.oel_probe.id
}

# ─── SSH Key ──────────────────────────────────────────────────────────────────

resource "tls_private_key" "oel_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ─── Virtual Machine Scale Set (Part 2 & 4) ───────────────────────────────────

resource "azurerm_linux_virtual_machine_scale_set" "oel_vmss" {
  name                = "OEL-VMSS"
  resource_group_name = azurerm_resource_group.oel_rg.name
  location            = azurerm_resource_group.oel_rg.location
  sku                 = "Standard_D2s_v3"
  instances           = 2
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.oel_key.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "NIC"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.oel_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.oel_bap.id]
    }
  }

  # Serves the identical styled portfolio referencing Azure Blob URLs
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    # Install Apache
    apt-get update -y
    apt-get install apache2 -y
    systemctl start apache2
    systemctl enable apache2

    # Create portfolio index page
    cat << 'HTML_EOF' > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Haseen Ullah - Cloud Portfolio</title>
        <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&display=swap" rel="stylesheet">
        <style>
            :root {
                --primary: #4f46e5;
                --secondary: #06b6d4;
                --background: #0f172a;
                --card-bg: #1e293b;
                --text: #f8fafc;
                --text-muted: #94a3b8;
            }
            * {
                box-sizing: border-box;
                margin: 0;
                padding: 0;
                font-family: 'Outfit', sans-serif;
            }
            body {
                background-color: var(--background);
                color: var(--text);
                line-height: 1.6;
            }
            header {
                background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
                padding: 4rem 2rem;
                text-align: center;
                border-bottom: 4px solid var(--secondary);
            }
            header h1 {
                font-size: 3rem;
                font-weight: 700;
                margin-bottom: 0.5rem;
            }
            header p.student-info {
                font-size: 1.25rem;
                color: #e2e8f0;
                margin-bottom: 0.25rem;
            }
            .container {
                max-width: 1000px;
                margin: 3rem auto;
                padding: 0 2rem;
            }
            section {
                margin-bottom: 4rem;
            }
            h2 {
                font-size: 2rem;
                border-bottom: 2px solid var(--primary);
                padding-bottom: 0.5rem;
                margin-bottom: 1.5rem;
            }
            .grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
                gap: 2rem;
            }
            .card {
                background-color: var(--card-bg);
                border: 1px solid #334155;
                border-radius: 12px;
                padding: 2rem;
                transition: transform 0.3s ease, border-color 0.3s ease;
            }
            .card:hover {
                transform: translateY(-5px);
                border-color: var(--secondary);
            }
            .card h3 {
                color: var(--secondary);
                margin-bottom: 1rem;
                font-size: 1.4rem;
            }
            .card p {
                color: var(--text-muted);
                font-size: 0.95rem;
            }
            .btn-group {
                display: flex;
                gap: 1.5rem;
                margin-top: 2rem;
                justify-content: center;
                flex-wrap: wrap;
            }
            .btn {
                display: inline-block;
                padding: 0.75rem 1.5rem;
                border-radius: 8px;
                background-color: var(--primary);
                color: var(--text);
                text-decoration: none;
                font-weight: 600;
                transition: background-color 0.3s ease;
            }
            .btn-secondary {
                background-color: transparent;
                border: 2px solid var(--secondary);
                color: var(--secondary);
            }
            .btn:hover {
                background-color: #3b82f6;
            }
            .btn-secondary:hover {
                background-color: var(--secondary);
                color: var(--background);
            }
            footer {
                text-align: center;
                padding: 2rem;
                color: var(--text-muted);
                border-top: 1px solid #334155;
                margin-top: 4rem;
            }
        </style>
    </head>
    <body>
        <header>
            <h1>Haseen Ullah</h1>
            <p class="student-info">Reg No: <strong>22MDSWE238</strong></p>
            <p class="student-info">Course: <strong>SE-409L Cloud Computing Lab (Spring 2026)</strong></p>
        </header>
        
        <div class="container">
            <section id="projects">
                <h2>Featured Projects</h2>
                <div class="grid">
                    <div class="card">
                        <h3>AI-Driven Threat Detection</h3>
                        <p>Implemented an automated ML monitoring workflow that pipes real-time application and network traffic logs into AWS SageMaker, triggering CloudWatch anomaly alerts when potential threat patterns are identified.</p>
                    </div>
                    <div class="card">
                        <h3>Cloud-Native E-Commerce</h3>
                        <p>Architected a highly available multi-tier e-commerce catalog application backed by an AWS Application Load Balancer and Auto Scaling Groups, ensuring seamless scaling during high traffic loads.</p>
                    </div>
                    <div class="card">
                        <h3>Serverless Task Orchestrator</h3>
                        <p>Built a microservice system that schedules and runs recurring administrative cron tasks using AWS Lambda, API Gateway, and Amazon DynamoDB, resulting in a zero-management, 100% serverless infrastructure.</p>
                    </div>
                </div>
            </section>

            <section id="assets">
                <h2>Verified Cloud Storage Assets</h2>
                <p style="color: var(--text-muted); margin-bottom: 1.5rem;">The following links dynamically fetch verified curriculum artifacts hosted securely on our public Azure Blob storage account container:</p>
                <div class="btn-group">
                    <a href="https://${azurerm_storage_account.portfolio_storage.name}.blob.core.windows.net/${azurerm_storage_container.assets_container.name}/${azurerm_storage_blob.resume.name}" class="btn" target="_blank">Download Resume (Azure Blob URL)</a>
                    <a href="https://${azurerm_storage_account.portfolio_storage.name}.blob.core.windows.net/${azurerm_storage_container.assets_container.name}/${azurerm_storage_blob.project_doc.name}" class="btn btn-secondary" target="_blank">View Project Documentation</a>
                </div>
            </section>
        </div>

        <footer>
            <p>&copy; 2026 Haseen Ullah (22MDSWE238). Powered by Azure VMSS & Blob Storage.</p>
        </footer>
    </body>
    </html>
    HTML_EOF
  EOF
  )
}

# ─── Log Analytics Workspace & Monitoring (Part 5 Equivalent) ────────────────

resource "azurerm_log_analytics_workspace" "oel_workspace" {
  name                = "oel-workspace-${random_id.suffix.hex}"
  location            = azurerm_resource_group.oel_rg.location
  resource_group_name = azurerm_resource_group.oel_rg.name
  sku                 = "PerGB2018"
}

# Metric Alert: Trigger if average CPU > 80%
resource "azurerm_monitor_metric_alert" "oel_cpu_alert" {
  name                = "oel-vmss-cpu-high-alert"
  resource_group_name = azurerm_resource_group.oel_rg.name
  scopes              = [azurerm_linux_virtual_machine_scale_set.oel_vmss.id]
  description         = "This alert monitors VMSS average CPU usage and triggers when average CPU exceeds 80%"
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
}
