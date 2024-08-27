# Define the GCP provider configuration.
provider "google" {
  credentials = file("<path-to-your-service-account-key>.json")  # Replace with the path to your GCP service account key
  project     = "<your-gcp-project-id>"  # Replace with your GCP project ID
  region      = "us-central1"  # Replace with your desired GCP region
}

variable "cidr" {
  default = "10.0.0.0/16"
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "sub1" {
  name          = "terraform-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc_network.id
  region        = "us-central1"
}

resource "google_compute_firewall" "web_sg" {
  name    = "web-firewall"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["web"]
}

resource "google_compute_instance" "server" {
  name         = "terraform-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.sub1.id
    access_config {
      // Ephemeral public IP
    }
  }

  tags = ["web"]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3-pip
    pip3 install flask
    echo "from flask import Flask, jsonify
    app = Flask(__name__)
    @app.route('/')
    def hello_world():
        return jsonify(message='Hello from GCP VM!')
    if __name__ == '__main__':
        app.run(host='0.0.0.0', port=80)" > /home/ubuntu/app.py
    python3 /home/ubuntu/app.py &
  EOT

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"  # Replace with your public key
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")  # Replace with the path to your private key
    host        = self.network_interface[0].access_config[0].nat_ip
  }

  provisioner "file" {
    source      = "app.py"  # Replace with the path to your local file
    destination = "/home/ubuntu/app.py"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",
      "sudo apt-get install -y python3-pip",
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo python3 app.py &",
    ]
  }
}

output "instance_ip" {
  value = google_compute_instance.server.network_interface[0].access_config[0].nat_ip
}
