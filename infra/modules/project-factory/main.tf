resource "random_string" "project_suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "google_project" "project" {
  name            = "${var.project_id}-${random_string.project_suffix.result}"
  project_id      = "${var.project_id}-${random_string.project_suffix.result}"
  org_id          = var.folder_id == null || var.folder_id == "" ? var.organization_id : null
  folder_id       = var.folder_id == "" ? null : var.folder_id
  billing_account = var.billing_account

  labels = var.labels

  auto_create_network = false
  deletion_policy     = "DELETE"
}

resource "google_project_service" "project_services" {
  for_each = toset(var.services)

  project = google_project.project.project_id
  service = each.value

  disable_dependent_services = true
  disable_on_destroy         = true
}

# Enable organization policies if specified
resource "google_project_organization_policy" "policies" {
  for_each = var.organization_policies

  project    = google_project.project.project_id
  constraint = each.key

  dynamic "boolean_policy" {
    for_each = each.value.type == "boolean" ? [each.value] : []
    content {
      enforced = boolean_policy.value.enforced
    }
  }

  dynamic "list_policy" {
    for_each = each.value.type == "list" ? [each.value] : []
    content {
      inherit_from_parent = lookup(list_policy.value, "inherit_from_parent", null)

      dynamic "allow" {
        for_each = lookup(list_policy.value, "allow", null) != null ? [list_policy.value.allow] : []
        content {
          all    = lookup(allow.value, "all", null)
          values = lookup(allow.value, "values", null)
        }
      }

      dynamic "deny" {
        for_each = lookup(list_policy.value, "deny", null) != null ? [list_policy.value.deny] : []
        content {
          all    = lookup(deny.value, "all", null)
          values = lookup(deny.value, "values", null)
        }
      }
    }
  }

  depends_on = [google_project.project]
}
