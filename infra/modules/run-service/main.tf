resource "google_cloud_run_v2_service" "this" {
  project             = var.project_id
  location            = var.region
  name                = var.name
  ingress             = var.ingress
  iap_enabled         = var.iap_enabled
  deletion_protection = var.deletion_protection
  labels              = var.labels

  template {
    service_account       = var.service_account
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    labels                = var.labels

    scaling {
      min_instance_count = 0 # scale to zero
      max_instance_count = var.max_instances
    }

    # Direct VPC egress: only private ranges (Cloud SQL) go through the VPC.
    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = var.network
        subnetwork = var.subnetwork
      }
    }

    containers {
      image = var.image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = true # request-based billing
        startup_cpu_boost = true
      }

      dynamic "env" {
        for_each = var.env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_env
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      # Cloud Run ignores the Dockerfile HEALTHCHECK: probes live on the service.
      startup_probe {
        initial_delay_seconds = 0
        period_seconds        = 3
        timeout_seconds       = 2
        failure_threshold     = 10
        http_get {
          path = var.health_path
        }
      }

      liveness_probe {
        period_seconds    = 30
        timeout_seconds   = 3
        failure_threshold = 3
        http_get {
          path = var.health_path
        }
      }
    }
  }
}
