variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "bastion_name" {
  description = "Bastion name"
  type        = string
}

variable "network" {
  description = "Network name"
  type        = string
}

variable "subnet" {
  description = "Subnet name"
  type        = string
}

variable "zone" {
  description = "Zone"
  type        = string
}

variable "iap_users" {
  description = "IAP users"
  type        = list(string)
}
