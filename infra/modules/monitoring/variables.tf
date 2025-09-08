variable "monitoring_project_id" {
  description = "Monitoring project ID"
  type        = string
}

variable "monitored_projects" {
  description = "Map of project IDs to monitor with static keys"
  type        = map(string)
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "notification_email" {
  description = "Email for monitoring notifications"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
