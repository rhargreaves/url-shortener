output "vpc_network" {
  description = "The VPC network self link"
  value       = google_compute_network.vpc.self_link
}

output "vpc_name" {
  description = "The VPC network name"
  value       = google_compute_network.vpc.name
}

output "app_subnet" {
  description = "Application subnet self link"
  value       = google_compute_subnetwork.app_subnet.self_link
}

output "gke_subnet" {
  description = "GKE subnet self link"
  value       = google_compute_subnetwork.gke_subnet.self_link
}

output "ci_subnet" {
  description = "CI/CD subnet self link"
  value       = google_compute_subnetwork.ci_subnet.self_link
}

output "app_subnet_cidr" {
  description = "Application subnet CIDR"
  value       = google_compute_subnetwork.app_subnet.ip_cidr_range
}

output "gke_subnet_cidr" {
  description = "GKE subnet CIDR"
  value       = google_compute_subnetwork.gke_subnet.ip_cidr_range
}

output "gke_pods_range_name" {
  description = "GKE pods secondary range name"
  value       = "gke-pods"
}

output "gke_services_range_name" {
  description = "GKE services secondary range name"
  value       = "gke-services"
}

output "private_dns_zone" {
  description = "Private DNS zone name"
  value       = google_dns_managed_zone.private_zone.name
}