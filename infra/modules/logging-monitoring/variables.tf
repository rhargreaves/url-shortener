variable "logging_project_id" {
  description = "Logging and monitoring project ID"
  type        = string
}

variable "monitored_projects" {
  description = "Map of project IDs to monitor with static keys"
  type        = map(string)
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "notification_email" {
  description = "Email for monitoring notifications"
  type        = string
  default     = "ops@example.com"
}

variable "service_domain" {
  description = "Domain name for uptime checks"
  type        = string
  default     = "short.example.com"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
