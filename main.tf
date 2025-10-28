terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Reserve static IP
resource "google_compute_address" "static_ip" {
  name   = "demo-web-static-ip"
  region = var.region
}

# Firewall: Allow HTTP
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-demo"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags = ["http-server"]
}

# Firewall: Allow HTTPS
resource "google_compute_firewall" "allow_https" {
  name    = "allow-https-demo"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  target_tags = ["https-server"]
}

# Compute Instance
resource "google_compute_instance" "demo_vm" {
  name         = "test-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-noble-amd64-v20251021"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata = {
    startup-script = file("${path.module}/startup.sh")
  }

  tags = ["http-server", "https-server"]

  # Wait for startup script to complete (optional but helpful)
  timeouts {
    create = "10m"
    update = "10m"
  }
}
