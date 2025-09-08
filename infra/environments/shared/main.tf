terraform {
  required_version = ">= 1.0"

  backend "gcs" {
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

locals {
  shared_projects = {
    security   = "${var.project_prefix}-security"
    monitoring = "${var.project_prefix}-monitoring"
  }

  common_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

module "security" {
  source = "../../modules/project-factory"

  project_id      = local.shared_projects.security
  organization_id = var.organization_id
  billing_account = var.billing_account
  folder_id       = var.folder_id

  services = [
    "securitycenter.googleapis.com",
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudasset.googleapis.com",
    "policytroubleshooter.googleapis.com"
  ]

  labels = local.common_labels
}

module "monitoring" {
  source = "../../modules/project-factory"

  project_id      = local.shared_projects.monitoring
  organization_id = var.organization_id
  billing_account = var.billing_account
  folder_id       = var.folder_id

  services = [
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
    "cloudprofiler.googleapis.com",
    "clouderrorreporting.googleapis.com"
  ]

  labels = local.common_labels
}

module "security_config" {
  source = "../../modules/security"

  security_project_id = module.security.project_id
  organization_id     = var.organization_id
  labels              = local.common_labels

  depends_on = [module.security]
}

module "monitoring_config" {
  source             = "../../modules/monitoring"
  region             = var.region
  notification_email = var.notification_email

  monitoring_project_id = module.monitoring.project_id
  monitored_projects = {
    security = module.security.project_id
  }

  labels = local.common_labels

  depends_on = [module.monitoring]
}
