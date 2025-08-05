variable "project_id" {
  description = "Project ID (will have random suffix added)"
  type        = string
}

variable "organization_id" {
  description = "Organization ID"
  type        = string
}

variable "billing_account" {
  description = "Billing account ID"
  type        = string
}

variable "folder_id" {
  description = "Folder ID (optional, set to empty string if not using folders)"
  type        = string
}

variable "services" {
  description = "List of GCP services to enable"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to the project"
  type        = map(string)
  default     = {}
}

variable "organization_policies" {
  description = "Organization policies to apply to the project"
  type = map(object({
    type                = string
    enforced            = optional(bool)
    inherit_from_parent = optional(bool)
    allow = optional(object({
      all    = optional(bool)
      values = optional(list(string))
    }))
    deny = optional(object({
      all    = optional(bool)
      values = optional(list(string))
    }))
  }))
  default = {}
}
