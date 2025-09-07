locals {
  environment_projects = {
    app     = "${var.project_prefix}-${var.environment}-app-${var.version_suffix}"
    network = "${var.project_prefix}-shared-network-${var.version_suffix}"
  }

  shared_projects = {
    security           = "${var.project_prefix}-security-${var.version_suffix}"
    logging_monitoring = "${var.project_prefix}-monitoring-${var.version_suffix}"
  }

  common_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

module "shared_network" {
  source = "./modules/project-factory"

  project_id      = local.shared_projects.network
  organization_id = var.organization_id
  billing_account = var.billing_account
  folder_id       = var.folder_id

  services = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com"
  ]

  labels = local.common_labels
}

module "app_project" {
  source = "./modules/project-factory"

  project_id      = local.environment_projects.app
  organization_id = var.organization_id
  billing_account = var.billing_account
  folder_id       = var.folder_id

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

module "shared_vpc" {
  source = "./modules/shared-vpc"

  project_id = module.shared_network.project_id
  region     = var.region
  zones      = var.zones

  # Service projects that will use the shared VPC
  service_projects = {
    app = module.app_project.project_id
  }

  labels = local.common_labels

  depends_on = [module.shared_network]
}

module "gke" {
  source = "./modules/gke"

  project_id   = module.app_project.project_id
  cluster_name = "${var.environment}-url-shortener"
  region       = var.region
  zones        = var.zones

  network_project_id = module.shared_network.project_id
  network            = module.shared_vpc.vpc_network
  subnet             = module.shared_vpc.gke_subnet

  pods_range_name     = module.shared_vpc.gke_pods_range_name
  services_range_name = module.shared_vpc.gke_services_range_name
  domain_name         = var.domain_name

  enable_istio     = true
  enable_autopilot = true
  node_count       = 3
  machine_type     = "e2-standard-2"

  labels = local.common_labels

  depends_on = [module.app_project, module.shared_vpc]
}
