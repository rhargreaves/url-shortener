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
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
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

variable "enable_istio" {
  description = "Enable Istio service mesh on GKE clusters"
  type        = bool
}

variable "enable_autopilot" {
  description = "Use GKE Autopilot mode"
  type        = bool
}

variable "node_count" {
  description = "Number of nodes per zone (if not using Autopilot)"
  type        = number
}

variable "machine_type" {
  description = "Machine type for GKE nodes (if not using Autopilot)"
  type        = string
}