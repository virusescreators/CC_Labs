terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
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

provider "azuread" {}

# --- Local Variable for Region (to mimic global/regional concept) ---
locals {
  location = "East US"
}

# --- Resource Group (Container) ---
resource "azurerm_resource_group" "lab2_rg" {
  name     = "Lab2-RG"
  location = local.location
}

# --- Regional Service: Virtual Network (VPC equivalent) ---
resource "azurerm_virtual_network" "lab2_vnet" {
  name                = "Lab2-Regional-VNet"
  location            = azurerm_resource_group.lab2_rg.location
  resource_group_name = azurerm_resource_group.lab2_rg.name
  address_space       = ["10.0.0.0/16"]
}

# --- Subnet ---
resource "azurerm_subnet" "lab2_subnet" {
  name                 = "Lab2-Subnet"
  resource_group_name  = azurerm_resource_group.lab2_rg.name
  virtual_network_name = azurerm_virtual_network.lab2_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# --- Global Service (sort of): Storage Account (S3 equivalent) ---
# Storage Account names must be globally unique
resource "random_id" "storage_suffix" {
  byte_length = 4
}

resource "azurerm_storage_account" "lab2_storage" {
  name                     = "lab2store${random_id.storage_suffix.hex}"
  resource_group_name      = azurerm_resource_group.lab2_rg.name
  location                 = azurerm_resource_group.lab2_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Description = "Storage Accounts have global endpoint namespace but regional data"
  }
}

# --- Global Service: Azure AD Group (IAM Group equivalent) ---
resource "azuread_group" "lab2_global_group" {
  display_name     = "Lab2-Global-Group"
  security_enabled = true
}
