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
  service_name          = "vida-interview-prod"
  environment           = "prod"
  container_image       = var.container_image
  commit_sha            = var.commit_sha
  
  # Production-specific settings
  cpu_limit             = "2000m"
  memory_limit          = "1Gi"
  min_instances         = "1"
  max_instances         = "20"
  allow_public_access   = true
}
