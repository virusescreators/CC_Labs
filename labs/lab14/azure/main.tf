terraform {
  backend "s3" {
    bucket         = "tfstate-haseen-22mdswe238"
    key            = "lab14/azure/terraform.tfstate"
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

resource "azurerm_resource_group" "lab14_rg" {
  name     = "Lab14-Monitoring-RG-${random_id.suffix.hex}"
  location = "East US"
}

# ─── Networking ───────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "lab14_vnet" {
  name                = "HaseenUllah-22MDSWE238-Lab14-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab14_rg.location
  resource_group_name = azurerm_resource_group.lab14_rg.name

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab14-VNet"
  }
}

resource "azurerm_subnet" "lab14_subnet" {
  name                 = "Lab14-Subnet"
  resource_group_name  = azurerm_resource_group.lab14_rg.name
  virtual_network_name = azurerm_virtual_network.lab14_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "lab14_pip" {
  name                = "Lab14-PIP"
  location            = azurerm_resource_group.lab14_rg.location
  resource_group_name = azurerm_resource_group.lab14_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "lab14_nsg" {
  name                = "Lab14-NSG"
  location            = azurerm_resource_group.lab14_rg.location
  resource_group_name = azurerm_resource_group.lab14_rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "Lab14-NSG"
  }
}

resource "azurerm_subnet_network_security_group_association" "lab14_nsg_assoc" {
  subnet_id                 = azurerm_subnet.lab14_subnet.id
  network_security_group_id = azurerm_network_security_group.lab14_nsg.id
}

resource "azurerm_network_interface" "lab14_nic" {
  name                = "Lab14-NIC"
  location            = azurerm_resource_group.lab14_rg.location
  resource_group_name = azurerm_resource_group.lab14_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab14_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab14_pip.id
  }
}

# ─── SSH Key ──────────────────────────────────────────────────────────────────

resource "tls_private_key" "lab14_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ─── Virtual Machine ──────────────────────────────────────────────────────────

resource "azurerm_linux_virtual_machine" "lab14_vm" {
  name                = "Lab14-VM"
  resource_group_name = azurerm_resource_group.lab14_rg.name
  location            = azurerm_resource_group.lab14_rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.lab14_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.lab14_key.public_key_openssh
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
    # Update packages
    apt-get update -y

    # Create custom application log directory and file
    mkdir -p /var/log/custom-app
    touch /var/log/custom-app/app.log
    chmod 666 /var/log/custom-app/app.log

    # Create background log generator daemon writing both to a custom log file and syslog (via logger)
    cat << 'OUTER_EOF' > /usr/local/bin/log-generator.sh
    #!/bin/bash
    while true; do
      CPU_LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | sed 's/^[ \t]*//')
      MEM_FREE=$(free -m | awk '/Mem:/ { print $4 }')
      MSG="Lab14-App-Monitor: Periodic log heartbeat. CPU Load Avg: $CPU_LOAD | Free Memory: $MEM_FREE MB"
      
      # Write to custom log file
      echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $MSG" >> /var/log/custom-app/app.log
      
      # Forward to Syslog using local user facility
      logger -p user.info -t custom-app "$MSG"
      
      sleep 10
    done
    OUTER_EOF

    chmod +x /usr/local/bin/log-generator.sh
    # Launch log generator daemon
    nohup /usr/local/bin/log-generator.sh > /dev/null 2>&1 &
  EOF
  )

  tags = {
    Name = "Lab14-Monitoring-VM"
  }
}

# ─── Log Analytics Workspace ──────────────────────────────────────────────────

resource "azurerm_log_analytics_workspace" "lab14_law" {
  name                = "lab14-law-${random_id.suffix.hex}"
  location            = azurerm_resource_group.lab14_rg.location
  resource_group_name = azurerm_resource_group.lab14_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Name = "Lab14-LogAnalytics-Workspace"
  }
}

# ─── Azure Monitor Agent (AMA) VM Extension ───────────────────────────────────

resource "azurerm_virtual_machine_extension" "lab14_ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.lab14_vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.28"
  auto_upgrade_minor_version = true

  tags = {
    Name = "Lab14-AMA-Extension"
  }
}

# ─── Data Collection Rule (DCR) ───────────────────────────────────────────────

resource "azurerm_monitor_data_collection_rule" "lab14_dcr" {
  name                = "lab14-dcr-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab14_rg.name
  location            = azurerm_resource_group.lab14_rg.location

  destinations {
    log_analytics {
      name                  = "destination-log-analytics"
      workspace_resource_id = azurerm_log_analytics_workspace.lab14_law.id
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Syslog"]
    destinations = ["destination-log-analytics"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\Memory\\% Used Memory",
        "\\LogicalDisk(_Total)\\% Free Space"
      ]
      name = "perf-counters"
    }

    syslog {
      streams = ["Microsoft-Syslog"]
      facility_names = [
        "user"
      ]
      log_levels = [
        "Info",
        "Notice",
        "Warning",
        "Error",
        "Critical"
      ]
      name = "syslog-collector"
    }
  }

  tags = {
    Name = "Lab14-DataCollectionRule"
  }
}

# ─── Data Collection Rule Association (DCRA) ─────────────────────────────────

resource "azurerm_monitor_data_collection_rule_association" "lab14_dcra" {
  name                    = "lab14-dcra-${random_id.suffix.hex}"
  target_resource_id      = azurerm_linux_virtual_machine.lab14_vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.lab14_dcr.id
}
