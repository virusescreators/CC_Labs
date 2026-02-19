variable "azure_domain_name" {
  description = "The primary domain name for the Azure AD tenant (e.g., contoso.onmicrosoft.com)"
  type        = string
  default     = "change-me.onmicrosoft.com" # Default to force user to notice, or we can try a clever fallback in main.tf
}
