output "folder_id" {
  value = google_folder.platform.folder_id
}

output "projects" {
  value = { for k, p in module.project : k => { id = p.project_id, number = p.number } }
}

output "groups" {
  value = local.group_emails
}

output "tfstate_bucket" {
  value = google_storage_bucket.tfstate.name
}

output "artifact_registry" {
  value = {
    apps     = "${var.region}-docker.pkg.dev/${local.shared_project}/${google_artifact_registry_repository.apps.repository_id}"
    apps_dev = "${var.region}-docker.pkg.dev/${local.shared_project}/${google_artifact_registry_repository.apps_dev.repository_id}"
  }
}

output "deployer_email" {
  value = google_service_account.deployer.email
}

# Value of gcpWorkloadIdentityProvider in pipeline-templates/templates/platform-vars.yml.
output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.azdo.name
}
