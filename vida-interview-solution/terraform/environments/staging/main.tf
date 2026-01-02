terraform {
  required_version = "~> 1.6.0"
  
  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "cloud_run" {
  source = "../../modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "vida-interview-staging"
  environment           = "staging"
  container_image       = var.container_image
  commit_sha            = var.commit_sha
  
  # Staging-specific settings
  cpu_limit             = "1000m"
  memory_limit          = "512Mi"
  min_instances         = "0"
  max_instances         = "5"
  allow_public_access   = true
}
