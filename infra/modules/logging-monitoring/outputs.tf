output "performance_dataset_id" {
  description = "BigQuery dataset ID for performance analytics"
  value       = google_bigquery_dataset.performance_analytics.dataset_id
}

output "dashboard_url" {
  description = "URL to the monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.url_shortener_dashboard.id}?project=${var.logging_project_id}"
}

output "notification_channel_id" {
  description = "Monitoring notification channel ID"
  value       = google_monitoring_notification_channel.email.name
}

output "uptime_check_id" {
  description = "Uptime check configuration ID"
  value       = google_monitoring_uptime_check_config.url_shortener_uptime.name
}

output "alert_policy_ids" {
  description = "Alert policy IDs"
  value = {
    high_error_rate = google_monitoring_alert_policy.high_error_rate.name
    high_latency    = google_monitoring_alert_policy.high_latency.name
    pod_crash_loop  = google_monitoring_alert_policy.pod_crash_loop.name
  }
}