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

  labels = var.labels
}

# Secrets encryption key
resource "google_kms_crypto_key" "secrets_key" {
  name     = "secrets-encryption-key"
  key_ring = google_kms_key_ring.key_ring.id
  purpose  = "ENCRYPT_DECRYPT"

  rotation_period = "7776000s" # 90 days

  labels = var.labels
}

resource "google_pubsub_topic" "security_notifications" {
  project = var.security_project_id
  name    = "security-notifications"

  labels = var.labels
}

resource "google_monitoring_alert_policy" "high_risk_security_events" {
  project      = var.security_project_id
  display_name = "High Risk Security Events"
  combiner     = "OR"

  conditions {
    display_name = "Security Center High Severity Findings"

    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"logging.googleapis.com/user/security-events\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
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
