locals {
  environment_projects = {
    app = "${var.project_prefix}-${var.environment}-app"
    ci  = "${var.project_prefix}-${var.environment}-ci"
  }

  shared_projects = {
    network           = "${var.project_prefix}-shared-network"
    security         = "${var.project_prefix}-security"
    logging_monitoring = "${var.project_prefix}-logging-monitoring"
  }

  common_labels = {
    environment = var.environment
    project     = "url-shortener"
    managed_by  = "terraform"
  }
}

# Shared Network Project
module "shared_network" {
  source = "./modules/project-factory"

  project_id       = local.shared_projects.network
  project_name     = "URL Shortener - Shared Network"
  organization_id  = var.organization_id
  billing_account  = var.billing_account
  folder_id        = var.folder_id

  services = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com"
  ]

  labels = local.common_labels
}

# Security Project
module "security" {
  source = "./modules/project-factory"

  project_id       = local.shared_projects.security
  project_name     = "URL Shortener - Security"
  organization_id  = var.organization_id
  billing_account  = var.billing_account
  folder_id        = var.folder_id

  services = [
    "securitycenter.googleapis.com",
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudasset.googleapis.com",
    "policytroubleshooter.googleapis.com"
  ]

  labels = local.common_labels
}

# Logging and Monitoring Project
module "logging_monitoring" {
  source = "./modules/project-factory"

  project_id       = local.shared_projects.logging_monitoring
  project_name     = "URL Shortener - Logging & Monitoring"
  organization_id  = var.organization_id
  billing_account  = var.billing_account
  folder_id        = var.folder_id

  services = [
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
    "cloudprofiler.googleapis.com",
    "clouderrorreporting.googleapis.com"
  ]

  labels = local.common_labels
}

# Application Project
module "app_project" {
  source = "./modules/project-factory"

  project_id       = local.environment_projects.app
  project_name     = "URL Shortener - ${title(var.environment)} App"
  organization_id  = var.organization_id
  billing_account  = var.billing_account
  folder_id        = var.folder_id

  services = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "cloudrun.googleapis.com",
    "servicemesh.googleapis.com",
    "artifactregistry.googleapis.com",
    "redis.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com"
  ]

  labels = merge(local.common_labels, {
    tier = "application"
  })
}

# CI/CD Project
module "ci_project" {
  source = "./modules/project-factory"

  project_id       = local.environment_projects.ci
  project_name     = "URL Shortener - ${title(var.environment)} CI"
  organization_id  = var.organization_id
  billing_account  = var.billing_account
  folder_id        = var.folder_id

  services = [
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "sourcerepo.googleapis.com",
    "containeranalysis.googleapis.com",
    "binaryauthorization.googleapis.com"
  ]

  labels = merge(local.common_labels, {
    tier = "cicd"
  })
}

# Shared VPC Network
module "shared_vpc" {
  source = "./modules/shared-vpc"

  project_id = module.shared_network.project_id
  region     = var.region
  zones      = var.zones

  # Service projects that will use the shared VPC
  service_projects = [
    module.app_project.project_id,
    module.ci_project.project_id
  ]

  labels = local.common_labels

  depends_on = [module.shared_network]
}

# GKE Cluster
module "gke" {
  source = "./modules/gke"

  project_id        = module.app_project.project_id
  cluster_name      = "${var.environment}-url-shortener"
  region            = var.region
  zones             = var.zones

  network_project_id = module.shared_network.project_id
  network           = module.shared_vpc.vpc_network
  subnet            = module.shared_vpc.gke_subnet

  pods_range_name     = module.shared_vpc.gke_pods_range_name
  services_range_name = module.shared_vpc.gke_services_range_name
  domain_name        = var.domain_name

  enable_istio     = var.enable_istio
  enable_autopilot = var.enable_autopilot
  node_count      = var.node_count
  machine_type    = var.machine_type

  labels = local.common_labels

  depends_on = [module.app_project, module.shared_vpc]
}

# Security Configuration
module "security_config" {
  source = "./modules/security"

  security_project_id = module.security.project_id
  app_project_id     = module.app_project.project_id
  ci_project_id      = module.ci_project.project_id

  organization_id = var.organization_id

  labels = local.common_labels

  depends_on = [module.security, module.app_project, module.ci_project]
}

# Logging and Monitoring Configuration
module "logging_monitoring_config" {
  source = "./modules/logging-monitoring"

  logging_project_id = module.logging_monitoring.project_id
  monitored_projects = [
    module.app_project.project_id,
    module.ci_project.project_id,
    module.shared_network.project_id
  ]

  labels = local.common_labels

  depends_on = [module.logging_monitoring]
}