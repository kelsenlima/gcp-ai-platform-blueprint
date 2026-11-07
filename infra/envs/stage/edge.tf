# ---------- Layer 5: access (IAP directly on Cloud Run, no load balancer) ----------
# Google-managed OAuth client: no manual brand or OAuth client. No load balancer,
# certificate or DNS record: apps use their *.run.app URLs.

# Makes sure the IAP service agent exists before it gets roles.
resource "google_project_service_identity" "iap" {
  provider = google-beta
  count    = var.enable_edge ? 1 : 0

  project = local.project_id
  service = "iap.googleapis.com"
}

# run.invoker on the PROJECT for the IAP agent: it covers every service of the project,
# including the ones developers deploy (run.developer cannot change a service's IAM).
resource "google_project_iam_member" "iap_agent_invoker" {
  count = var.enable_edge ? 1 : 0

  project = local.project_id
  role    = "roles/run.invoker"
  member  = google_project_service_identity.iap[0].member
}
