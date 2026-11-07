provider "google" {
  region = var.region
}

# APIs that require a quota project with user credentials (Cloud Identity, Org Policy) use
# the shared project as quota/billing project.
provider "google" {
  alias                 = "identity"
  region                = var.region
  billing_project       = "${var.prefix}-shared"
  user_project_override = true
}
