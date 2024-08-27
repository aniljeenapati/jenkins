provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-vpc-network"
  auto_create_subnetworks = true
}

resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }

  tags = var.tags
}

output "instance_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

variable "project_id" {
  description = "regal-center-428511-h1"
  type        = string
}

variable "region" {
  description = "The region where the VM will be created"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone where the VM will be created"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "The name of the VM instance"
  type        = string
  default     = "terraform-vm"
}

variable "machine_type" {
  description = "The machine type for the VM"
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "The boot disk image"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "tags" {
  description = "Network tags for the VM instance"
  type        = list(string)
  default     = ['terra-jen']
}

