terraform {
  required_version = "~> 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Cloud Run Service
resource "google_cloud_run_service" "app" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  template {
    spec {
      containers {
        image = var.container_image

        env {
          name  = "SERVICE_NAME"
          value = var.service_name
        }

        env {
          name  = "APP_ENV"
          value = var.environment
        }

        env {
          name  = "GIT_COMMIT_SHA"
          value = var.commit_sha
        }

        resources {
          limits = {
            cpu    = var.cpu_limit
            memory = var.memory_limit
          }
        }

        ports {
          container_port = 8080
        }
      }

      container_concurrency = var.container_concurrency
      timeout_seconds       = var.timeout_seconds
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = var.min_instances
        "autoscaling.knative.dev/maxScale" = var.max_instances
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

# IAM policy to allow public access (adjust for production)
resource "google_cloud_run_service_iam_member" "public_access" {
  count = var.allow_public_access ? 1 : 0

  service  = google_cloud_run_service.app.name
  location = google_cloud_run_service.app.location
  project  = google_cloud_run_service.app.project
  role     = "roles/run.invoker"
  member   = "allUsers"
}
