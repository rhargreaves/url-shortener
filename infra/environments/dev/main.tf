terraform {
  required_version = ">= 1.0"

  backend "gcs" {
    # configured via backend config
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.1.1"
    }
  }
}

provider "google" {
  region = var.region
}

module "infrastructure" {
  source = "../../"

  organization_id = var.organization_id
  billing_account = var.billing_account
  folder_id       = var.folder_id
  region          = var.region
  zones           = var.zones
  environment     = var.environment
  project_prefix  = var.project_prefix
  domain_name     = var.domain_name
}
