terraform {
  backend "s3" {
    bucket         = "tfstate-haseen-22mdswe238"
    key            = "lab13/azure/terraform.tfstate"
    region         = "us-east-1"
  }

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
}

provider "azurerm" {
  features {}
}

resource "random_id" "suffix" {
  byte_length = 4
}

# ─── Resource Group ───────────────────────────────────────────────────────────

resource "azurerm_resource_group" "lab13_rg" {
  name     = "Lab13-CD-RG-${random_id.suffix.hex}"
  location = "East US"
}

# ─── App Service Plan ─────────────────────────────────────────────────────────

resource "azurerm_service_plan" "lab13_plan" {
  name                = "Lab13-AppPlan-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab13_rg.name
  location            = azurerm_resource_group.lab13_rg.location
  os_type             = "Linux"
  sku_name            = "B1" # Standard cost-efficient B1 tier
}

# ─── Linux Web App (Production) ───────────────────────────────────────────────

resource "azurerm_linux_web_app" "lab13_webapp" {
  name                = "lab13-webapp-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab13_rg.name
  location            = azurerm_resource_group.lab13_rg.location
  service_plan_id     = azurerm_service_plan.lab13_plan.id

  site_config {
    application_stack {
      node_version = "18-lts"
    }
    always_on = false # B1 and below doesn't strictly require always_on, keeps cost low
  }

  # Configures continuous deployment capability via local Git repository
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "0"
    "DEPLOYMENT_PROVIDER"      = "LocalGit"
    "ENV_STAGE"                = "Production"
  }

  tags = {
    Name        = "Lab13-Continuous-Deployment-WebApp"
    Environment = "Production"
  }
}

# ─── Linux Web App Slot (Staging Environment) ─────────────────────────────────

resource "azurerm_linux_web_app_slot" "lab13_staging_slot" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.lab13_webapp.id

  site_config {
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "0"
    "DEPLOYMENT_PROVIDER"      = "LocalGit"
    "ENV_STAGE"                = "Staging"
  }

  tags = {
    Name        = "Lab13-Continuous-Deployment-StagingSlot"
    Environment = "Staging"
  }
}
