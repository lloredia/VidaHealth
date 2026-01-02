output "service_url" {
  description = "Staging service URL"
  value       = module.cloud_run.service_url
}

output "service_name" {
  description = "Staging service name"
  value       = module.cloud_run.service_name
}
