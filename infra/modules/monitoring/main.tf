resource "google_monitoring_alert_policy" "pod_crash_loop" {
  project      = var.monitoring_project_id
  display_name = "Pod Crash Loop"
  combiner     = "OR"

  conditions {
    display_name = "Pod restart rate > 5 per hour"

    condition_threshold {
      filter          = "resource.type=\"k8s_container\" AND metric.type=\"kubernetes.io/container/restart_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5

      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    content   = "Pod is experiencing frequent restarts, indicating potential crash loop"
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_notification_channel" "email" {
  project      = var.monitoring_project_id
  display_name = "URL Shortener Alerts"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}
