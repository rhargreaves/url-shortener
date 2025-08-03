output "project_id" {
  description = "Project ID"
  value       = google_project.project.project_id
}

output "project_number" {
  description = "Project number"
  value       = google_project.project.number
}

output "project_name" {
  description = "Project name"
  value       = google_project.project.name
}

output "enabled_services" {
  description = "List of enabled services"
  value       = [for svc in google_project_service.project_services : svc.service]
}