output "project_id" {
  value = local.project_id
}

output "network" {
  value = var.enable_network ? {
    vpc    = module.network[0].network_name
    subnet = module.network[0].subnet_name
  } : null
}

output "sql" {
  value = var.enable_sql ? {
    instance        = module.cloudsql[0].instance_name
    connection_name = module.cloudsql[0].connection_name
    private_ip      = module.cloudsql[0].private_ip
    password_secret = module.cloudsql[0].password_secret_name
    scheduler_jobs  = [for j in google_cloud_scheduler_job.sql : j.name]
  } : null
}

output "run_runtime_email" {
  value = var.enable_iam ? google_service_account.run_runtime[0].email : null
}

output "hello_uri" {
  value = var.enable_run ? module.hello[0].uri : null
}
