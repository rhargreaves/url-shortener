resource "google_compute_instance" "bastion" {
  name         = var.bastion_name
  machine_type = "e2-micro"
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnet
    access_config {} # External IP
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  tags = ["bastion"]
}
