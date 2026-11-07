# Deploy identity of the Azure DevOps pipelines (Workload Identity Federation, azdo.tf).
# Its roles in dev and stage are granted in envs/<environment>.
resource "google_service_account" "deployer" {
  project      = local.shared_project
  account_id   = "deployer"
  display_name = "Pipeline deployer (Azure DevOps, keyless)"

  depends_on = [module.project]
}

# Nobody else acts as deployer@: it is the only identity that publishes to stage, and stage
# deployments only happen through the pipeline. No service account keys are ever created.
