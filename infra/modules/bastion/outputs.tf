output "bastion_private_ip" {
  description = "Bastion private IP"
  value       = google_compute_instance.bastion.network_interface[0].network_ip
}

output "bastion_public_ip" {
  description = "Bastion public IP"
  value       = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip
}
