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
  user_principal_name = "student-user@${data.azuread_client_config.current.object_id}.onmicrosoft.com" # Placeholder, improved logic below
  display_name        = "Student User"
  mail_nickname       = "student-user"
  password            = "P@ssw0rd1234!" # In real scenario, use random_password or requiring change
  force_password_change_on_last_login = true
}

# Better UPN logic requires knowing the tenant domain.
# We can use data source to fetch domains.

data "azuread_domains" "default" {
  only_initial = true
}

resource "azuread_user" "student_user_improved" {
  user_principal_name = "student-user@${data.azuread_domains.default.domains.0.domain_name}"
  display_name        = "Student User"
  mail_nickname       = "student-user"
  password            = "P@ssw0rd1234!" 
}
