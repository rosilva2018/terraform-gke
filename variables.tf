// Variables

variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region where the GKE cluster will be created"
  type        = string
  default     = "us-east1"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = ""
}

variable "machine_type" {
  description = "The machine type for the nodes"
  type        = string
  default     = "n1-standard-1"
}
