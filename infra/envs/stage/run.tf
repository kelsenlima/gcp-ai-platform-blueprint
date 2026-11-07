# ---------- Layer 4: Cloud Run (hello validation service) ----------
# No allUsers invoker: every request needs an identity with run.invoker (IAP or IAM).
# Ingress stays INGRESS_TRAFFIC_ALL: with IAP directly on Cloud Run, IAP protects every
# entry point, including the run.app URL.

module "hello" {
  source = "../../modules/run-service"
  count  = var.enable_run ? 1 : 0

  project_id          = local.project_id
  region              = var.region
  name                = "hello"
  image               = var.hello_image
  service_account     = google_service_account.run_runtime[0].email
  network             = module.network[0].network_id
  subnetwork          = module.network[0].subnet_id
  ingress             = "INGRESS_TRAFFIC_ALL"
  iap_enabled         = var.enable_edge
  deletion_protection = var.run_deletion_protection
  labels              = merge(local.labels, { app = "hello" })

  env = {
    APP_ENV         = var.environment
    VERTEX_PROJECT  = local.vertex_project
    VERTEX_LOCATION = var.vertex_location
    VERTEX_MODEL    = var.vertex_model
    DB_INSTANCE     = module.cloudsql[0].connection_name
    DB_NAME         = var.db_name
    DB_USER         = var.db_user
    # Changes when the password is rotated and forces a new revision, which reads the new secret.
    DB_PASSWORD_VERSION = tostring(var.sql_password_version)
  }

  secret_env = {
    DB_PASSWORD = module.cloudsql[0].password_secret_id
  }

  depends_on = [
    google_secret_manager_secret_iam_member.runtime_sql_password,
    google_artifact_registry_repository_iam_member.run_agent_reader,
    google_project_iam_member.this,
    google_project_iam_member.iap_agent_invoker,
  ]
}
