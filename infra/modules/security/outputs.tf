output "kms_key_ring_id" {
  description = "KMS key ring ID"
  value       = google_kms_key_ring.key_ring.id
}

output "database_key_id" {
  description = "Database encryption key ID"
  value       = google_kms_crypto_key.database_key.id
}

output "secrets_key_id" {
  description = "Secrets encryption key ID"
  value       = google_kms_crypto_key.secrets_key.id
}

output "database_url_secret_id" {
  description = "Database URL secret ID"
  value       = google_secret_manager_secret.database_url.secret_id
}

output "redis_url_secret_id" {
  description = "Redis URL secret ID"
  value       = google_secret_manager_secret.redis_url.secret_id
}

output "app_secret_key_secret_id" {
  description = "App secret key secret ID"
  value       = google_secret_manager_secret.app_secret_key.secret_id
}

output "security_notification_topic" {
  description = "Security notification Pub/Sub topic"
  value       = google_pubsub_topic.security_notifications.name
}

output "binary_authorization_policy" {
  description = "Binary Authorization policy"
  value       = google_binary_authorization_policy.policy.id
}

output "build_attestor_name" {
  description = "Binary Authorization attestor name"
  value       = google_binary_authorization_attestor.build_attestor.name
}
