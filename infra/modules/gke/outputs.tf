output "cluster_name" {
  description = "GKE cluster name"
  value       = var.enable_autopilot ? google_container_cluster.autopilot[0].name : google_container_cluster.primary[0].name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = var.enable_autopilot ? google_container_cluster.autopilot[0].endpoint : google_container_cluster.primary[0].endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = var.enable_autopilot ? google_container_cluster.autopilot[0].master_auth.0.cluster_ca_certificate : google_container_cluster.primary[0].master_auth.0.cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "GKE cluster location"
  value       = var.enable_autopilot ? google_container_cluster.autopilot[0].location : google_container_cluster.primary[0].location
}

output "service_account_email" {
  description = "GKE service account email"
  value       = google_service_account.gke_sa.email
}

output "load_balancer_ip" {
  description = "Load balancer static IP"
  value       = google_compute_global_address.lb_ip.address
}

output "ssl_certificate_id" {
  description = "SSL certificate ID"
  value       = google_compute_managed_ssl_certificate.ssl_cert.id
}