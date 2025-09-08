locals {
  subnet_cidr_blocks = {
    app = "10.1.0.0/24"
    gke = "10.2.0.0/16"
    ci  = "10.3.0.0/24"
  }

  secondary_ranges = {
    gke_pods     = "192.168.0.0/16"
    gke_services = "10.4.0.0/16"
  }
}

resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "shared-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  description = "Shared VPC for URL Shortener infrastructure"
}

resource "google_compute_shared_vpc_host_project" "host" {
  project = var.project_id

  depends_on = [google_compute_network.vpc]
}

resource "google_compute_shared_vpc_service_project" "service_projects" {
  for_each = var.service_projects

  host_project    = var.project_id
  service_project = each.value

  depends_on = [google_compute_shared_vpc_host_project.host]
}

resource "google_compute_subnetwork" "app_subnet" {
  project       = var.project_id
  name          = "app-subnet"
  ip_cidr_range = local.subnet_cidr_blocks.app
  region        = var.region
  network       = google_compute_network.vpc.self_link

  description = "Subnet for application workloads"

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "gke_subnet" {
  project       = var.project_id
  name          = "gke-subnet"
  ip_cidr_range = local.subnet_cidr_blocks.gke
  region        = var.region
  network       = google_compute_network.vpc.self_link

  description = "Subnet for GKE clusters"

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = local.secondary_ranges.gke_pods
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = local.secondary_ranges.gke_services
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "ci_subnet" {
  project       = var.project_id
  name          = "ci-subnet"
  ip_cidr_range = local.subnet_cidr_blocks.ci
  region        = var.region
  network       = google_compute_network.vpc.self_link

  description = "Subnet for CI/CD workloads"

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "shared-router"
  region  = var.region
  network = google_compute_network.vpc.self_link

  description = "Router for Cloud NAT"
}

resource "google_compute_router_nat" "nat" {
  project = var.project_id
  name    = "shared-nat"
  router  = google_compute_router.router.name
  region  = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "allow_internal" {
  project = var.project_id
  name    = "allow-internal"
  network = google_compute_network.vpc.self_link

  description = "Allow internal communication"

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    local.subnet_cidr_blocks.app,
    local.subnet_cidr_blocks.gke,
    local.subnet_cidr_blocks.ci,
    local.secondary_ranges.gke_pods,
    local.secondary_ranges.gke_services
  ]
}

resource "google_compute_firewall" "allow_health_checks" {
  project = var.project_id
  name    = "allow-health-checks"
  network = google_compute_network.vpc.self_link

  description = "Allow Google Cloud health checks"

  allow {
    protocol = "tcp"
    ports    = ["8080", "80", "443"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  target_tags = ["gke-node", "web-server"]
}

resource "google_compute_firewall" "allow_ssh_iap" {
  project = var.project_id
  name    = "allow-ssh-iap"
  network = google_compute_network.vpc.self_link

  description = "Allow SSH from Identity-Aware Proxy"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["ssh-allowed"]
}

resource "google_dns_managed_zone" "private_zone" {
  project     = var.project_id
  name        = "url-shortener-private"
  dns_name    = "urlshort.internal."
  description = "Private DNS zone for URL shortener services"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.self_link
    }
  }

  labels = var.labels
}

resource "google_project_iam_member" "gke_host_service_agent" {
  for_each = var.service_projects

  project = var.project_id
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:service-${data.google_project.service_project[each.key].number}@container-engine-robot.iam.gserviceaccount.com"
}

data "google_project" "service_project" {
  for_each   = var.service_projects
  project_id = each.value
}

resource "google_project_iam_member" "gke_network_user" {
  for_each = var.service_projects

  project = var.project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${data.google_project.service_project[each.key].number}@container-engine-robot.iam.gserviceaccount.com"
}
