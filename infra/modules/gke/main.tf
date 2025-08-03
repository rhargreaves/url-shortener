locals {
  gke_auth_scopes = [
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}

# Get GKE release channel and version
data "google_container_engine_versions" "gke_version" {
  location = var.region
  project  = var.project_id
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  count = var.enable_autopilot ? 0 : 1

  project  = var.project_id
  name     = var.cluster_name
  location = var.region

  # Network configuration
  network         = var.network
  subnetwork      = var.subnet
  networking_mode = "VPC_NATIVE"

  # Use Shared VPC
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Security configurations
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"

    master_global_access_config {
      enabled = true
    }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "VPC"
    }
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }

    dns_cache_config {
      enabled = true
    }

    gcp_filestore_csi_driver_config {
      enabled = true
    }

    gcs_fuse_csi_driver_config {
      enabled = true
    }


  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Shielded nodes
  enable_shielded_nodes = true

  # Binary Authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Network tags for firewall rules
  node_config {
    machine_type = var.machine_type
    disk_size_gb = 100
    disk_type    = "pd-ssd"

    oauth_scopes = local.gke_auth_scopes

    service_account = google_service_account.gke_sa.email

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    tags = ["gke-node"]

    labels = var.labels
  }

  # Resource labels
  resource_labels = var.labels

  # Initial node count (will be managed by node pool)
  remove_default_node_pool = true
  initial_node_count       = 1

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"



  # Release channel
  release_channel {
    channel = "REGULAR"
  }

  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
      node_config
    ]
  }
}

# GKE Autopilot Cluster
resource "google_container_cluster" "autopilot" {
  count = var.enable_autopilot ? 1 : 0

  project  = var.project_id
  name     = var.cluster_name
  location = var.region

  # Enable Autopilot
  enable_autopilot = true

  # Network configuration
  network         = var.network
  subnetwork      = var.subnet
  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Security configurations
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"

    master_global_access_config {
      enabled = true
    }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "VPC"
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Binary Authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Resource labels
  resource_labels = var.labels

  # Logging and monitoring
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS"
    ]
  }

  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS"
    ]

    managed_prometheus {
      enabled = true
    }
  }

  # Release channel
  release_channel {
    channel = "REGULAR"
  }

  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

# Node pool for standard GKE
resource "google_container_node_pool" "primary_nodes" {
  count = var.enable_autopilot ? 0 : 1

  project    = var.project_id
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary[0].name
  node_count = var.node_count

  # Node configuration
  node_config {
    preemptible  = false
    machine_type = var.machine_type
    disk_size_gb = 100
    disk_type    = "pd-ssd"

    oauth_scopes = local.gke_auth_scopes

    service_account = google_service_account.gke_sa.email

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    tags = ["gke-node"]

    labels = var.labels
  }

  # Autoscaling
  autoscaling {
    min_node_count = 1
    max_node_count = 10
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  # Management
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Service account for GKE nodes
resource "google_service_account" "gke_sa" {
  project    = var.project_id
  account_id = "${var.cluster_name}-sa"

  display_name = "GKE Service Account for ${var.cluster_name}"
  description  = "Service account for GKE cluster nodes"
}

# IAM bindings for GKE service account
resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# External IP for load balancer
resource "google_compute_global_address" "lb_ip" {
  project = var.project_id
  name    = "${var.cluster_name}-lb-ip"

  description = "Static IP for ${var.cluster_name} load balancer"
}

# SSL certificate for HTTPS
resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  project = var.project_id
  name    = "${var.cluster_name}-ssl-cert"

  managed {
    domains = [var.domain_name]
  }

  lifecycle {
    create_before_destroy = true
  }
}
