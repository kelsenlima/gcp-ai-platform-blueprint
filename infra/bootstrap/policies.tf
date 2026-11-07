# Default service accounts (Compute Engine, App Engine) get no automatic roles/editor in the
# folder's projects. Workloads use dedicated service accounts (deployer@, run-runtime@).
resource "google_org_policy_policy" "no_default_sa_grants" {
  provider = google.identity

  name   = "${google_folder.platform.name}/policies/iam.automaticIamGrantsForDefaultServiceAccounts"
  parent = google_folder.platform.name

  spec {
    rules {
      enforce = "TRUE"
    }
  }

  depends_on = [module.project]
}
