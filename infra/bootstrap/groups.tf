locals {
  groups = {
    admins = {
      email       = local.group_emails.admins
      description = "Platform administrators: own the AI platform folder"
    }
    devs = {
      email       = local.group_emails.devs
      description = "Developers: deploy and operate in dev, read-only in stage"
    }
    users = {
      email       = local.group_emails.users
      description = "Users: access the apps and demos in stage"
    }
  }
}

# Members are NOT managed here: people join and leave through the console.
# WITH_INITIAL_OWNER makes the identity running Terraform an OWNER of each group.
resource "google_cloud_identity_group" "this" {
  for_each = var.manage_groups ? local.groups : {}
  provider = google.identity

  parent               = "customers/${var.customer_id}"
  display_name         = split("@", each.value.email)[0]
  description          = each.value.description
  initial_group_config = "WITH_INITIAL_OWNER"

  group_key {
    id = each.value.email
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [module.project]
}

resource "google_folder_iam_member" "admins_owner" {
  folder = google_folder.platform.name
  role   = "roles/owner"
  member = "group:${local.group_emails.admins}"

  depends_on = [google_cloud_identity_group.this]
}
