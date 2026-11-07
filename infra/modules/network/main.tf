# Custom-mode VPC with no firewall rules: only the implied rules apply
# (deny all ingress, allow all egress).
resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "this" {
  project                  = var.project_id
  name                     = "${var.name}-${var.region}"
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

# Range reserved for Private Service Access (Cloud SQL private IP).
resource "google_compute_global_address" "psa" {
  project       = var.project_id
  name          = "${var.name}-psa"
  network       = google_compute_network.this.id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = split("/", var.psa_cidr)[0]
  prefix_length = tonumber(split("/", var.psa_cidr)[1])
  labels        = var.labels
}

resource "google_service_networking_connection" "psa" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa.name]
}
