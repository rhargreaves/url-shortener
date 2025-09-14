# Include all variables from the root module
variable "organization_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "billing_account" {
  description = "Billing account ID"
  type        = string
}

variable "folder_id" {
  description = "Folder ID where projects will be created (optional)"
  type        = string
}

variable "region" {
  description = "Primary GCP region"
  type        = string
}

variable "zones" {
  description = "GCP zones for multi-zone deployments"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod", "shared"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod' or 'shared'."
  }
}

variable "project_prefix" {
  description = "Prefix for all project names"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the URL shortener"
  type        = string
}

variable "iap_users" {
  description = "IAP users"
  type        = list(string)
}
