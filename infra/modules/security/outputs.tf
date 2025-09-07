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

output "security_notification_topic" {
  description = "Security notification Pub/Sub topic"
  value       = google_pubsub_topic.security_notifications.name
}
