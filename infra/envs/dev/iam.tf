# ---------- Layer 3: identities and IAM ----------
# Always google_*_iam_member (never _binding/_policy): additive, so it never overwrites
# bindings created by Google or by other teams.

data "google_project" "this" {
  count      = var.enable_iam ? 1 : 0
  project_id = local.project_id
}

resource "google_service_account" "run_runtime" {
  count = var.enable_iam ? 1 : 0

  project      = local.project_id
  account_id   = "run-runtime"
  display_name = "Cloud Run runtime (${var.environment})"
}

locals {
  deployer   = "serviceAccount:deployer@${local.shared_project_id}.iam.gserviceaccount.com"
  runtime_sa = var.enable_iam ? "serviceAccount:${google_service_account.run_runtime[0].email}" : null
  # Cloud Run service agent: the identity that pulls images from the shared Artifact Registry.
  run_agent = var.enable_iam ? "serviceAccount:service-${data.google_project.this[0].number}@serverless-robot-prod.iam.gserviceaccount.com" : null

  # dev: developers deploy directly, manage their own secrets and may log in to the database.
  # stage: developers only read; deploys only through the pipeline (deployer@).
  devs_roles = {
    dev = [
      "roles/run.developer",
      "roles/secretmanager.admin",
      "roles/cloudsql.client",
      "roles/cloudsql.viewer",
      "roles/cloudsql.instanceUser",
      "roles/cloudscheduler.jobRunner",
      "roles/logging.viewer",
      "roles/monitoring.viewer",
      "roles/iap.httpsResourceAccessor",
    ]
    stage = [
      "roles/run.viewer",
      "roles/logging.viewer",
      "roles/monitoring.viewer",
      "roles/iap.httpsResourceAccessor",
    ]
  }
  # Admins reach the apps through IAP without being in the devs group.
  admins_roles = {
    dev   = ["roles/iap.httpsResourceAccessor"]
    stage = ["roles/iap.httpsResourceAccessor"]
  }
  # Users only see stage, the demo environment.
  users_roles = {
    dev   = []
    stage = ["roles/iap.httpsResourceAccessor"]
  }

  project_bindings = !var.enable_iam ? {} : merge(
    # run.invoker: apps call internal APIs (services without IAP) with a run-runtime@ ID token.
    { for r in ["roles/cloudsql.client", "roles/logging.logWriter", "roles/run.invoker"] : "runtime/${r}" => { member = local.runtime_sa, role = r } },
    { "deployer/roles/run.admin" = { member = local.deployer, role = "roles/run.admin" } },
    { for r in local.devs_roles[var.environment] : "devs/${r}" => { member = "group:${local.group_devs}", role = r } },
    { for r in local.users_roles[var.environment] : "users/${r}" => { member = "group:${local.group_users}", role = r } },
    { for r in local.admins_roles[var.environment] : "admins/${r}" => { member = "group:${local.group_admins}", role = r } },
  )

  # Who can "act as" run-runtime@ (deploy services that run as it).
  runtime_act_as = !var.enable_iam ? {} : merge(
    { deployer = local.deployer },
    var.environment == "dev" ? { devs = "group:${local.group_devs}" } : {},
  )
}

resource "google_project_iam_member" "this" {
  for_each = local.project_bindings

  project = local.project_id
  role    = each.value.role
  member  = each.value.member
}

resource "google_service_account_iam_member" "runtime_act_as" {
  for_each = local.runtime_act_as

  service_account_id = google_service_account.run_runtime[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}

# dev only: developers impersonate run-runtime@ to test locally what only it can reach
# (e.g. Vertex AI in another project). Never in stage.
resource "google_service_account_iam_member" "devs_impersonate_runtime" {
  count = var.enable_iam && var.environment == "dev" ? 1 : 0

  service_account_id = google_service_account.run_runtime[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "group:${local.group_devs}"
}

# secretAccessor per secret, not on the project.
resource "google_secret_manager_secret_iam_member" "runtime_sql_password" {
  count = var.enable_iam && var.enable_sql ? 1 : 0

  secret_id = module.cloudsql[0].password_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = local.runtime_sa
}

# The Cloud Run agent reads images per repository: apps (pipeline) in both environments;
# apps-dev (manual developer builds) only in dev. Stage can never run a manual build.
resource "google_artifact_registry_repository_iam_member" "run_agent_reader" {
  for_each = var.enable_iam ? toset(var.environment == "dev" ? ["apps", "apps-dev"] : ["apps"]) : toset([])

  project    = local.shared_project_id
  location   = var.region
  repository = each.key
  role       = "roles/artifactregistry.reader"
  member     = local.run_agent
}

# Vertex AI: the only binding in the Vertex project when it is not this one.
resource "google_project_iam_member" "runtime_vertex" {
  count = var.enable_iam ? 1 : 0

  project = local.vertex_project
  role    = "roles/aiplatform.user"
  member  = local.runtime_sa
}

# dev only: IAM database login for the developers group (no shared password).
resource "google_sql_user" "devs_iam" {
  count = var.enable_iam && var.enable_sql && var.environment == "dev" ? 1 : 0

  project  = local.project_id
  instance = module.cloudsql[0].instance_name
  name     = local.group_devs
  type     = "CLOUD_IAM_GROUP"
}
