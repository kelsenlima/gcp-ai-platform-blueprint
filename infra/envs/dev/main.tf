locals {
  project_id        = "${var.prefix}-${var.environment}"
  shared_project_id = "${var.prefix}-shared"
  labels            = merge(var.labels, { environment = var.environment })

  group_admins = "${var.group_admins_name}@${var.group_domain}"
  group_devs   = "${var.group_devs_name}@${var.group_domain}"
  group_users  = "${var.group_users_name}@${var.group_domain}"

  # Vertex AI can live in another project (e.g. a shared data/AI project): then only one
  # binding is added there (iam.tf) and the API is not enabled here.
  vertex_project = var.vertex_project_id != "" ? var.vertex_project_id : local.project_id

  services = concat([
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "iap.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudscheduler.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    # Required by user_project_override (the project is its own quota project).
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ], var.vertex_project_id == "" ? ["aiplatform.googleapis.com"] : [])
}

# ---------- Layer 1: network (APIs + VPC + PSA) ----------

resource "google_project_service" "this" {
  for_each = var.enable_network ? toset(local.services) : toset([])

  project            = local.project_id
  service            = each.value
  disable_on_destroy = false
}

module "network" {
  source = "../../modules/network"
  count  = var.enable_network ? 1 : 0

  project_id  = local.project_id
  region      = var.region
  subnet_cidr = var.subnet_cidr
  psa_cidr    = var.psa_cidr
  labels      = local.labels

  depends_on = [google_project_service.this]
}

# ---------- Layer 2: Cloud SQL (private IP only) ----------

# Ephemeral value: never written to the state or the plan. It is only sent to the database
# and to the secret when sql_password_version changes.
ephemeral "random_password" "sql_app" {
  count = var.enable_sql ? 1 : 0

  length           = 32
  override_special = "-_"
}

module "cloudsql" {
  source = "../../modules/cloudsql"
  count  = var.enable_sql ? 1 : 0

  project_id          = local.project_id
  region              = var.region
  name                = "ai-pg-${var.environment}"
  tier                = var.sql_tier
  network_id          = module.network[0].network_id
  psa_connection      = module.network[0].psa_connection
  deletion_protection = var.sql_deletion_protection
  backup_start_time   = var.sql_backup_start_time
  db_name             = var.db_name
  db_user             = var.db_user
  password            = ephemeral.random_password.sql_app[0].result
  password_version    = var.sql_password_version
  labels              = local.labels
}

# Scheduled start/stop (dev only): the instance is billed only while it runs.
locals {
  sql_schedule = var.enable_sql && var.sql_schedule
  sql_schedule_jobs = {
    stop  = { schedule = var.sql_stop_cron, policy = "NEVER", description = "Stops the Cloud SQL instance (weekdays)" }
    start = { schedule = var.sql_start_cron, policy = "ALWAYS", description = "Starts the Cloud SQL instance (weekdays)" }
  }
}

resource "google_service_account" "sql_scheduler" {
  count = local.sql_schedule ? 1 : 0

  project      = local.project_id
  account_id   = "sql-scheduler"
  display_name = "Cloud Scheduler: starts and stops Cloud SQL"
}

resource "google_project_iam_member" "sql_scheduler" {
  count = local.sql_schedule ? 1 : 0

  project = local.project_id
  role    = "roles/cloudsql.editor"
  member  = "serviceAccount:${google_service_account.sql_scheduler[0].email}"
}

resource "google_cloud_scheduler_job" "sql" {
  for_each = local.sql_schedule ? local.sql_schedule_jobs : {}

  project     = local.project_id
  region      = var.region
  name        = "sql-${each.key}"
  description = each.value.description
  schedule    = each.value.schedule
  time_zone   = var.sql_schedule_time_zone

  http_target {
    http_method = "PATCH"
    uri         = "https://sqladmin.googleapis.com/v1/projects/${local.project_id}/instances/${module.cloudsql[0].instance_name}"
    headers     = { "Content-Type" = "application/json" }
    body        = base64encode(jsonencode({ settings = { activationPolicy = each.value.policy } }))

    oauth_token {
      service_account_email = google_service_account.sql_scheduler[0].email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  depends_on = [google_project_iam_member.sql_scheduler]
}
