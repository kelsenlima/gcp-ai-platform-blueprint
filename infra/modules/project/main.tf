resource "google_project" "this" {
  project_id          = var.project_id
  name                = var.name
  folder_id           = var.folder_id
  billing_account     = var.billing_account
  labels              = var.labels
  auto_create_network = var.auto_create_network
  deletion_policy     = "PREVENT"
}

resource "google_project_service" "this" {
  for_each = toset(var.services)

  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false
}
