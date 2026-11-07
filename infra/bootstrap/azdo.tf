# Workload Identity Federation with Azure DevOps: the pipelines get Google credentials
# without any service account key.
#
# The token comes from an Azure Resource Manager service connection configured with workload
# identity federation (manual), backed by an Entra app registration that has no secret, no
# role in Azure and no API permission. Issuer: the Entra tenant.
#   sub = <prefix>/sc/<organization-id>/<service-connection-id>
# The token does not carry the Azure DevOps project: the restriction to one project comes
# from the service connection ID, so never share that service connection with other projects.
resource "google_iam_workload_identity_pool" "azdo" {
  project                   = local.shared_project
  workload_identity_pool_id = "azure-devops"
  display_name              = "Azure DevOps"
  description               = "Pipelines of ${var.azdo_org_name}/${var.azdo_project_name}"

  depends_on = [module.project]
}

resource "google_iam_workload_identity_pool_provider" "azdo" {
  project                            = local.shared_project
  workload_identity_pool_id          = google_iam_workload_identity_pool.azdo.workload_identity_pool_id
  workload_identity_pool_provider_id = "azdo-org"
  display_name                       = "Azure DevOps organization"
  description                        = "Service connections of the ${var.azdo_org_name} organization"

  oidc {
    issuer_uri        = "https://login.microsoftonline.com/${var.azdo_tenant_id}/v2.0"
    allowed_audiences = var.azdo_token_audiences
  }

  # The full sub is longer than 127 characters (the limit of google.subject), so the subject
  # is <organization-id>/<service-connection-id>.
  attribute_mapping = {
    "google.subject"         = "assertion.sub.split('/sc/')[1]"
    "attribute.organization" = "assertion.sub.split('/sc/')[1].split('/')[0]"
  }

  # Only tokens from this organization; other organizations in the same tenant are rejected.
  attribute_condition = "assertion.sub.split('/sc/')[1].startsWith('${var.azdo_org_id}/')"
}

# Only the configured service connection can act as deployer@. Any other service connection
# of the organization still exchanges its token, but gets a principal with no permission.
resource "google_service_account_iam_member" "azdo_deployer" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.azdo.name}/subject/${var.azdo_org_id}/${var.azdo_service_connection_id}"
}
