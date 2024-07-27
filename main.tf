# Cluster k8s

terraform {
  backend "gcs" {
    bucket  = ""
    prefix  = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # Enabling GKE features

  network    = ""
  subnetwork = ""

  deletion_protection = false

  # Define a primary node pool (on-demand instances)

  node_pool {
    name = "primary-pool"

    initial_node_count = 1

    node_config {
      preemptible  = false
      machine_type = var.machine_type

      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]

      metadata = {
        disable-legacy-endpoints = "true"
      }

      labels = {
        node-pool = "primary"
      }

    }
    autoscaling {
      min_node_count = 1
      max_node_count = 3
    }
  }

  # Define a spot node pool

  node_pool {
    name = "spot-pool"

    initial_node_count = 1

    node_config {
      preemptible  = true
      machine_type = var.machine_type

      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]

      metadata = {
        disable-legacy-endpoints = "true"
      }

      labels = {
        node-pool = "spot"
      }
    }

    autoscaling {
      min_node_count = 1
      max_node_count = 3
    }

  }
}

# Construção do kubeconfig

data "google_client_config" "default" {}

output "kubeconfig" {
  value = templatefile("kubeconfig.tpl", {
    endpoint               = google_container_cluster.primary.endpoint
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
    client_certificate     = base64decode(google_container_cluster.primary.master_auth.0.client_certificate)
    client_key             = base64decode(google_container_cluster.primary.master_auth.0.client_key)
    token                  = data.google_client_config.default.access_token
  })
  sensitive = true
}


output "endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
}

