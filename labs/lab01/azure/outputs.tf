output "student_azure_ad_user_upn" {
  value = azuread_user.student_user.user_principal_name
}

output "student_azure_ad_user_initial_password" {
  value     = azuread_user.student_user.password
  sensitive = true
}

