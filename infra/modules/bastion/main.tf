resource "google_compute_instance" "bastion" {
  name         = var.bastion_name
  machine_type = "e2-micro"
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-13"
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
