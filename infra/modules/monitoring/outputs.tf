output "notification_channel_id" {
  description = "Monitoring notification channel ID"
  value       = google_monitoring_notification_channel.email.name
}

output "alert_policy_ids" {
  description = "Alert policy IDs"
  value = {
    pod_crash_loop = google_monitoring_alert_policy.pod_crash_loop.name
  }
}
