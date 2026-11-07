resource "google_sql_database_instance" "this" {
  project             = var.project_id
  name                = var.name
  region              = var.region
  database_version    = "POSTGRES_16"
  deletion_protection = var.deletion_protection

  settings {
    # Shared-core tiers (db-f1-micro, db-g1-small) only exist in the Enterprise edition;
    # for POSTGRES_16 the default would be Enterprise Plus.
    edition = "ENTERPRISE"
    # API-level protection (console/gcloud), on top of Terraform's deletion_protection.
    deletion_protection_enabled = var.deletion_protection
    tier                        = var.tier
    availability_type           = "ZONAL"
    disk_type                   = "PD_SSD"
    disk_size                   = 10
    disk_autoresize             = true
    user_labels                 = var.labels

    backup_configuration {
      enabled    = true
      start_time = var.backup_start_time

      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    # Private IP only: no public address, reachable from the VPC (Cloud Run Direct VPC egress).
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
      ssl_mode        = "ENCRYPTED_ONLY" # apps: sslmode=require or the Cloud SQL connector
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }

  lifecycle {
    # The dev start/stop schedule flips ALWAYS/NEVER; Terraform must not revert it.
    ignore_changes = [settings[0].activation_policy]
  }

  depends_on = [var.psa_connection]
}

resource "google_sql_database" "this" {
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = var.db_name
}

# Write-only password: never stored in the state or shown in the plan. It is written to the
# database and to Secret Manager only when password_version changes.
resource "google_sql_user" "app" {
  project             = var.project_id
  instance            = google_sql_database_instance.this.name
  name                = var.db_user
  type                = "BUILT_IN"
  password_wo         = var.password
  password_wo_version = var.password_version
  # Postgres cannot drop a user that owns objects; the user goes away with the instance.
  deletion_policy = "ABANDON"
}

resource "google_secret_manager_secret" "password" {
  project   = var.project_id
  secret_id = "${var.name}-${var.db_user}-password"
  labels    = var.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "password" {
  secret                 = google_secret_manager_secret.password.id
  secret_data_wo         = var.password
  secret_data_wo_version = var.password_version
}
