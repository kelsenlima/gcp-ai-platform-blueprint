output "network_id" {
  value = google_compute_network.this.id
}

output "network_name" {
  value = google_compute_network.this.name
}

output "subnet_id" {
  value = google_compute_subnetwork.this.id
}

output "subnet_name" {
  value = google_compute_subnetwork.this.name
}

# Used by Cloud SQL to wait for the PSA peering.
output "psa_connection" {
  value = google_service_networking_connection.psa.id
}
