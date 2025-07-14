output "id" {
  description = "ID of the Service Account"
  value       = confluent_service_account.this.id
}

output "api_version" {
  description = "API Version of the Service Account"
  value       = confluent_service_account.this.api_version
}