# Log sink for centralized logging
resource "google_logging_project_sink" "app_logs" {
  for_each = var.monitored_projects

  project     = each.value
  name        = "url-shortener-app-logs"
  destination = "logging.googleapis.com/projects/${var.logging_project_id}/logs/app-logs"

  filter = <<-EOT
    resource.type="gke_container" OR
    resource.type="k8s_container" OR
    resource.type="cloud_run_revision" OR
    resource.type="gce_instance"
  EOT

  unique_writer_identity = true
}

# Log sink for security events
resource "google_logging_project_sink" "security_logs" {
  for_each = var.monitored_projects

  project     = each.value
  name        = "url-shortener-security-logs"
  destination = "logging.googleapis.com/projects/${var.logging_project_id}/logs/security-logs"

  filter = <<-EOT
    protoPayload.serviceName="cloudaudit.googleapis.com" OR
    protoPayload.serviceName="k8s.io" OR
    severity>=ERROR
  EOT

  unique_writer_identity = true
}

# Log sink for performance metrics
resource "google_logging_project_sink" "performance_logs" {
  for_each = var.monitored_projects

  project     = each.value
  name        = "url-shortener-performance-logs"
  destination = "bigquery.googleapis.com/projects/${var.logging_project_id}/datasets/performance_analytics"

  filter = <<-EOT
    resource.type="gke_container" AND
    (jsonPayload.latency_ms>0 OR jsonPayload.response_time>0)
  EOT

  unique_writer_identity = true
}

# BigQuery dataset for log analytics
resource "google_bigquery_dataset" "performance_analytics" {
  project    = var.logging_project_id
  dataset_id = "performance_analytics"
  location   = var.region

  description = "Performance analytics for URL shortener"

  delete_contents_on_destroy = false

  labels = var.labels
}

# IAM for log sinks
resource "google_project_iam_member" "log_sink_writer" {
  for_each = google_logging_project_sink.app_logs

  project = var.logging_project_id
  role    = "roles/logging.logWriter"
  member  = each.value.writer_identity
}

resource "google_project_iam_member" "bigquery_data_editor" {
  for_each = google_logging_project_sink.performance_logs

  project = var.logging_project_id
  role    = "roles/bigquery.dataEditor"
  member  = each.value.writer_identity
}

# Custom metrics for application monitoring
resource "google_monitoring_metric_descriptor" "url_shortener_requests" {
  project      = var.logging_project_id
  type         = "custom.googleapis.com/url_shortener/requests_total"
  metric_kind  = "CUMULATIVE"
  value_type   = "INT64"
  display_name = "URL Shortener Requests"
  description  = "Total number of URL shortener requests"

  labels {
    key         = "method"
    value_type  = "STRING"
    description = "HTTP method"
  }

  labels {
    key         = "status_code"
    value_type  = "STRING"
    description = "HTTP status code"
  }
}

resource "google_monitoring_metric_descriptor" "url_shortener_latency" {
  project      = var.logging_project_id
  type         = "custom.googleapis.com/url_shortener/request_latency"
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  display_name = "URL Shortener Request Latency"
  description  = "Request latency in milliseconds"

  labels {
    key         = "method"
    value_type  = "STRING"
    description = "HTTP method"
  }
}

# Dashboard for application monitoring
resource "google_monitoring_dashboard" "url_shortener_dashboard" {
  project = var.logging_project_id
  dashboard_json = jsonencode({
    displayName = "URL Shortener Dashboard"

    gridLayout = {
      widgets = [
        {
          title = "Request Rate"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"custom.googleapis.com/url_shortener/requests_total\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
                targetAxis = "Y1"
              }
            ]
            timeshiftDuration = "0s"
            yAxis = {
              label = "Requests per second"
              scale = "LINEAR"
            }
          }
        },
        {
          title = "Request Latency"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"custom.googleapis.com/url_shortener/request_latency\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                targetAxis = "Y1"
              }
            ]
            timeshiftDuration = "0s"
            yAxis = {
              label = "Latency (ms)"
              scale = "LINEAR"
            }
          }
        },
        {
          title = "Error Rate"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"custom.googleapis.com/url_shortener/requests_total\" AND metric.label.status_code!=\"200\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
                targetAxis = "Y1"
              }
            ]
            timeshiftDuration = "0s"
            yAxis = {
              label = "Errors per second"
              scale = "LINEAR"
            }
          }
        },
        {
          title = "GKE Pod Status"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_pod\" AND metric.type=\"kubernetes.io/pod/phase\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metric.label.phase"]
                    }
                  }
                }
                targetAxis = "Y1"
              }
            ]
            timeshiftDuration = "0s"
            yAxis = {
              label = "Pod count"
              scale = "LINEAR"
            }
          }
        }
      ]
    }
  })
}

# Alert policies
resource "google_monitoring_alert_policy" "high_error_rate" {
  project      = var.logging_project_id
  display_name = "High Error Rate"
  combiner     = "OR"

  conditions {
    display_name = "Error rate > 5%"

    condition_threshold {
      filter          = "metric.type=\"custom.googleapis.com/url_shortener/requests_total\" AND metric.label.status_code!=\"200\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    content   = "Error rate has exceeded 5% for the URL shortener service"
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "high_latency" {
  project      = var.logging_project_id
  display_name = "High Request Latency"
  combiner     = "OR"

  conditions {
    display_name = "Average latency > 1000ms"

    condition_threshold {
      filter          = "metric.type=\"custom.googleapis.com/url_shortener/request_latency\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1000

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    content   = "Average request latency has exceeded 1000ms for the URL shortener service"
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "pod_crash_loop" {
  project      = var.logging_project_id
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

# Notification channel
resource "google_monitoring_notification_channel" "email" {
  project      = var.logging_project_id
  display_name = "URL Shortener Alerts"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}

# Uptime check for the service
resource "google_monitoring_uptime_check_config" "url_shortener_uptime" {
  project      = var.logging_project_id
  display_name = "URL Shortener Uptime Check"
  timeout      = "10s"
  period       = "300s"

  http_check {
    port           = 443
    use_ssl        = true
    path           = "/health"
    request_method = "GET"
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.logging_project_id
      host       = var.service_domain
    }
  }

  content_matchers {
    content = "OK"
    matcher = "CONTAINS_STRING"
  }
}
