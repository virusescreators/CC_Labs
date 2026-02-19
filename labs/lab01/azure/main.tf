terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
  }
}

provider "azuread" {
  # Configuration via environment variables (ARM_CLIENT_ID, etc.)
}

# --- Data Source: Client Config ---
data "azuread_client_config" "current" {}

# --- Azure AD User: student-user ---
# Note: Creating users requires User.ReadWrite.All permission
resource "azuread_user" "student_user" {
  user_principal_name = "student-user@${var.azure_domain_name}"
  display_name        = "Student User"
  mail_nickname       = "student-user"
  password            = "P@ssw0rd1234!"
}

