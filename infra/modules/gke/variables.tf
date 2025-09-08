variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zones" {
  description = "GCP zones"
  type        = list(string)
}

variable "network_project_id" {
  description = "Shared VPC host project ID"
  type        = string
}

variable "network" {
  description = "VPC network self link"
  type        = string
}

variable "subnet" {
  description = "Subnet self link"
  type        = string
}

variable "pods_range_name" {
  description = "Secondary range name for pods"
  type        = string
  default     = "gke-pods"
}

variable "services_range_name" {
  description = "Secondary range name for services"
  type        = string
  default     = "gke-services"
}

variable "enable_istio" {
  description = "Enable Istio service mesh"
  type        = bool
  default     = true
}

variable "enable_autopilot" {
  description = "Use GKE Autopilot mode"
  type        = bool
  default     = true
}

variable "node_count" {
  description = "Number of nodes per zone (only for standard GKE)"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Machine type for nodes (only for standard GKE)"
  type        = string
  default     = "e2-standard-4"
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
