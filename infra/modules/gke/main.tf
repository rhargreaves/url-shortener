locals {
  gke_auth_scopes = [
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}

data "google_container_engine_versions" "gke_version" {
  location = var.region
  project  = var.project_id
}

resource "google_container_cluster" "primary" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.region

  network         = var.network
  subnetwork      = "projects/${var.network_project_id}/regions/${var.region}/subnetworks/gke-subnet"
  networking_mode = "VPC_NATIVE"

  deletion_protection = false

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

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

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  enable_shielded_nodes = true

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

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

  resource_labels = var.labels

  remove_default_node_pool = true
  initial_node_count       = 1

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  release_channel {
    channel = "REGULAR"
  }

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

resource "google_container_node_pool" "primary_nodes" {
  project    = var.project_id
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    preemptible  = false
    machine_type = var.machine_type
    disk_size_gb = 25
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

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

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
