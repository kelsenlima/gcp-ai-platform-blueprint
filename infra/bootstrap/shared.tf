locals {
  shared_project = module.project["shared"].project_id
}

# ---------- Terraform state ----------

resource "google_storage_bucket" "tfstate" {
  project                     = local.shared_project
  name                        = "${var.prefix}-tfstate"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = merge(var.labels, { environment = "shared" })

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [module.project]
}

# The bucket IAM policy is AUTHORITATIVE: it removes the convenience bindings (project
# owners/editors/viewers, including the ones inherited from the organization). Only the
# admins group can read the state.
data "google_iam_policy" "tfstate" {
  # Read/write objects (state and lock files).
  binding {
    role    = "roles/storage.objectAdmin"
    members = ["group:${local.group_emails.admins}"]
  }

  # Manage the bucket and its IAM, without object access. Without this binding Terraform
  # loses the ability to read the bucket after applying the authoritative policy.
  binding {
    role    = google_project_iam_custom_role.bucket_admin_no_data.id
    members = ["group:${local.group_emails.admins}"]
  }
}

resource "google_project_iam_custom_role" "bucket_admin_no_data" {
  project     = local.shared_project
  role_id     = "bucketAdminNoData"
  title       = "Bucket management without object access"
  description = "Read, update and manage the IAM of buckets, without reading or writing objects."
  permissions = [
    "storage.buckets.get",
    "storage.buckets.update",
    "storage.buckets.getIamPolicy",
    "storage.buckets.setIamPolicy",
  ]

  depends_on = [module.project]
}

resource "google_storage_bucket_iam_policy" "tfstate" {
  bucket      = google_storage_bucket.tfstate.name
  policy_data = data.google_iam_policy.tfstate.policy_data

  depends_on = [google_cloud_identity_group.this]
}

# ---------- Artifact Registry ----------

# apps: images built by the pipeline. The only repository stage can read from.
resource "google_artifact_registry_repository" "apps" {
  project       = local.shared_project
  location      = var.region
  repository_id = "apps"
  format        = "DOCKER"
  description   = "Pipeline images (promoted from dev to stage by digest)"
  labels        = merge(var.labels, { environment = "shared" })

  cleanup_policy_dry_run = false

  # KEEP wins over DELETE: delete everything except the 20 most recent versions of each image.
  cleanup_policies {
    id     = "keep-20-most-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 20
    }
  }

  cleanup_policies {
    id     = "delete-the-rest"
    action = "DELETE"
    condition {
      tag_state = "ANY"
    }
  }

  depends_on = [module.project]
}

# Only deployer@ (the pipeline) writes to apps.
resource "google_artifact_registry_repository_iam_member" "apps_deployer" {
  project    = local.shared_project
  location   = google_artifact_registry_repository.apps.location
  repository = google_artifact_registry_repository.apps.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.deployer.email}"
}

# apps-dev: manual builds from the developers' machines. Readable only by dev, so a manual
# build can never become the stage image.
resource "google_artifact_registry_repository" "apps_dev" {
  project       = local.shared_project
  location      = var.region
  repository_id = "apps-dev"
  format        = "DOCKER"
  description   = "Manual developer builds (dev only, never promoted to stage)"
  labels        = merge(var.labels, { environment = "dev" })

  cleanup_policy_dry_run = false

  # Keep the 5 most recent versions of each image; the rest is deleted after 7 days.
  cleanup_policies {
    id     = "keep-5-most-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 5
    }
  }

  cleanup_policies {
    id     = "delete-after-7-days"
    action = "DELETE"
    condition {
      tag_state  = "ANY"
      older_than = "604800s"
    }
  }

  depends_on = [module.project]
}

resource "google_artifact_registry_repository_iam_member" "apps_dev_devs" {
  project    = local.shared_project
  location   = google_artifact_registry_repository.apps_dev.location
  repository = google_artifact_registry_repository.apps_dev.name
  role       = "roles/artifactregistry.writer"
  member     = "group:${local.group_emails.devs}"

  depends_on = [google_cloud_identity_group.this]
}
