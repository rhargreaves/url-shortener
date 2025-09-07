variable "security_project_id" {
  description = "Security project ID"
  type        = string
}

variable "organization_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gke_cluster_name" {
  description = "GKE cluster name for Binary Authorization"
  type        = string
  default     = "url-shortener"
}

variable "security_email" {
  description = "Email for security notifications"
  type        = string
  default     = "security@example.com"
}

variable "pgp_public_key" {
  description = "PGP public key for Binary Authorization attestor"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
