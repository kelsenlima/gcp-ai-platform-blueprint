locals {
  group_emails = {
    admins = "${var.group_admins_name}@${var.group_domain}"
    devs   = "${var.group_devs_name}@${var.group_domain}"
    users  = "${var.group_users_name}@${var.group_domain}"
  }

  projects = {
    # shared never enables the Compute API, so it never gets a default network.
    shared = {
      auto_create_network = true
      services = [
        "cloudidentity.googleapis.com",
        "cloudresourcemanager.googleapis.com",
        "artifactregistry.googleapis.com",
        "storage.googleapis.com",
        "iam.googleapis.com",
        "serviceusage.googleapis.com",
        "orgpolicy.googleapis.com",      # quota project for org policy calls (provider google.identity)
        "sts.googleapis.com",            # exchanges the Azure DevOps token (federation)
        "iamcredentials.googleapis.com", # deployer@ access tokens for federated pipelines
      ]
    }
    # dev/stage: the default network is deleted (the provider enables compute.googleapis.com
    # to do so). Their APIs are enabled in envs/<environment>.
    dev   = { auto_create_network = false, services = [] }
    stage = { auto_create_network = false, services = [] }
  }
}

resource "google_folder" "platform" {
  display_name        = var.folder_name
  parent              = "organizations/${var.org_id}"
  deletion_protection = true
}

module "project" {
  source   = "../modules/project"
  for_each = local.projects

  project_id          = "${var.prefix}-${each.key}"
  name                = "${var.prefix}-${each.key}"
  folder_id           = google_folder.platform.folder_id
  billing_account     = var.billing_account
  auto_create_network = each.value.auto_create_network
  services            = each.value.services
  labels              = merge(var.labels, { environment = each.key })
}
