output "shared_network_project_id" {
  description = "Shared network project ID"
  value       = module.shared_network.project_id
}

output "security_project_id" {
  description = "Security project ID"
  value       = module.security.project_id
}

output "monitoring_project_id" {
  description = "Monitoring project ID"
  value       = module.monitoring.project_id
}

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "shared_vpc_network" {
  description = "Shared VPC network self link"
  value       = module.shared_vpc.vpc_network
}

output "app_subnet" {
  description = "Application subnet self link"
  value       = module.shared_vpc.app_subnet
}

output "gke_subnet" {
  description = "GKE subnet self link"
  value       = module.shared_vpc.gke_subnet
}

output "load_balancer_ip" {
  description = "Load balancer external IP"
  value       = module.gke.load_balancer_ip
}
