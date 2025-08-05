variable "project_id" {
  description = "Project ID for the shared VPC"
  type        = string
}

variable "region" {
  description = "Primary region for resources"
  type        = string
}

variable "zones" {
  description = "Zones for multi-zone deployments"
  type        = list(string)
}

variable "service_projects" {
  description = "Map of service project IDs to attach to shared VPC with static keys"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
