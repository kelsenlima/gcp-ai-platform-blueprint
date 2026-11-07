# The environment project is its own quota/billing project for API calls (avoids the shared
# quota of the default gcloud client).
provider "google" {
  project               = local.project_id
  region                = var.region
  billing_project       = local.project_id
  user_project_override = true
}

provider "google-beta" {
  project               = local.project_id
  region                = var.region
  billing_project       = local.project_id
  user_project_override = true
}
