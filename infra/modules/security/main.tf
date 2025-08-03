# KMS key ring for encryption
resource "google_kms_key_ring" "key_ring" {
  project  = var.security_project_id
  name     = "url-shortener-keys"
  location = var.region
}

# Database encryption key
resource "google_kms_crypto_key" "database_key" {
  name     = "database-encryption-key"
  key_ring = google_kms_key_ring.key_ring.id
  purpose  = "ENCRYPT_DECRYPT"

  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }

  labels = var.labels
}

# Secrets encryption key
resource "google_kms_crypto_key" "secrets_key" {
  name     = "secrets-encryption-key"
  key_ring = google_kms_key_ring.key_ring.id
  purpose  = "ENCRYPT_DECRYPT"

  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }

  labels = var.labels
}

# Secret Manager secrets
resource "google_secret_manager_secret" "database_url" {
  project   = var.app_project_id
  secret_id = "database-url"

  replication {
    automatic = true
  }

  labels = var.labels
}

resource "google_secret_manager_secret" "redis_url" {
  project   = var.app_project_id
  secret_id = "redis-url"

  replication {
    automatic = true
  }

  labels = var.labels
}

resource "google_secret_manager_secret" "app_secret_key" {
  project   = var.app_project_id
  secret_id = "app-secret-key"

  replication {
    automatic = true
  }

  labels = var.labels
}

# Security Command Center notification
resource "google_scc_notification_config" "basic_notification" {
  config_id    = "url-shortener-notifications"
  organization = var.organization_id
  description  = "Security notifications for URL shortener"
  pubsub_topic = google_pubsub_topic.security_notifications.id

  streaming_config {
    filter = "category=\"MALWARE\" OR category=\"OPEN_FIREWALL\" OR severity=\"HIGH\" OR severity=\"CRITICAL\""
  }
}

# Pub/Sub topic for security notifications
resource "google_pubsub_topic" "security_notifications" {
  project = var.security_project_id
  name    = "security-notifications"

  labels = var.labels
}

# Binary Authorization policy
resource "google_binary_authorization_policy" "policy" {
  project = var.app_project_id

  admission_whitelist_patterns {
    name_pattern = "gcr.io/${var.app_project_id}/*"
  }

  admission_whitelist_patterns {
    name_pattern = "us-central1-docker.pkg.dev/${var.app_project_id}/*"
  }

  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"

    require_attestations_by = [
      google_binary_authorization_attestor.build_attestor.name
    ]
  }

  cluster_admission_rules {
    cluster                 = "${var.region}.${var.gke_cluster_name}"
    evaluation_mode        = "REQUIRE_ATTESTATION"
    enforcement_mode       = "ENFORCED_BLOCK_AND_AUDIT_LOG"

    require_attestations_by = [
      google_binary_authorization_attestor.build_attestor.name
    ]
  }
}

# Binary Authorization attestor
resource "google_binary_authorization_attestor" "build_attestor" {
  project = var.app_project_id
  name    = "build-attestor"

  attestation_authority_note {
    note_reference = google_container_analysis_note.note.name

    public_keys {
      ascii_armored_pgp_public_key = var.pgp_public_key
      id                          = "pgp-key-1"
    }
  }
}

# Container Analysis note
resource "google_container_analysis_note" "note" {
  project = var.app_project_id
  name    = "build-note"

  attestation_authority {
    hint {
      human_readable_name = "Build Attestor"
    }
  }
}

# Organization policies
resource "google_org_policy_policy" "require_shielded_vm" {
  count = var.organization_id != "" ? 1 : 0

  name   = "projects/${var.app_project_id}/policies/compute.requireShieldedVm"
  parent = "projects/${var.app_project_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "disable_serial_port" {
  count = var.organization_id != "" ? 1 : 0

  name   = "projects/${var.app_project_id}/policies/compute.disableSerialPortAccess"
  parent = "projects/${var.app_project_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "require_ssl_load_balancers" {
  count = var.organization_id != "" ? 1 : 0

  name   = "projects/${var.app_project_id}/policies/compute.requireSslLoad Balancers"
  parent = "projects/${var.app_project_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Security monitoring
resource "google_monitoring_alert_policy" "high_risk_security_events" {
  project      = var.security_project_id
  display_name = "High Risk Security Events"
  combiner     = "OR"

  conditions {
    display_name = "Security Center High Severity Findings"

    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"logging.googleapis.com/user/security-events\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.security_email.name]

  documentation {
    content   = "High risk security event detected in the URL shortener infrastructure"
    mime_type = "text/markdown"
  }
}

# Notification channel for security alerts
resource "google_monitoring_notification_channel" "security_email" {
  project      = var.security_project_id
  display_name = "Security Alerts Email"
  type         = "email"

  labels = {
    email_address = var.security_email
  }
}