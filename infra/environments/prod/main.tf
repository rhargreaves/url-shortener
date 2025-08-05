terraform {
  required_version = ">= 1.0"

  # Configure backend for state management
  backend "gcs" {
    bucket = "rh-urlshort-terraform-state-prod-v1" # Replace with your bucket
    prefix = "prod/terraform.tfstate"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# Configure providers
provider "google" {
  region = var.region
}

provider "google-beta" {
  region = var.region
}

# Include main infrastructure
module "infrastructure" {
  source = "../../"

  # Pass through all variables
  organization_id  = var.organization_id
  billing_account  = var.billing_account
  folder_id        = var.folder_id
  region           = var.region
  zones            = var.zones
  environment      = var.environment
  project_prefix   = var.project_prefix
  domain_name      = var.domain_name
  enable_istio     = var.enable_istio
  enable_autopilot = var.enable_autopilot
  node_count       = var.node_count
  machine_type     = var.machine_type
  version_suffix   = var.version_suffix
}
