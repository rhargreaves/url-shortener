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

resource "google_monitoring_notification_channel" "security_email" {
  project      = var.security_project_id
  display_name = "Security Alerts Email"
  type         = "email"

  labels = {
    email_address = var.security_email
  }
}
