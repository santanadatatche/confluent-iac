output "connector_id" {
  description = "ID of the created connector"
  value       = confluent_connector.this.id
}

output "connector_status" {
  description = "Status of the connector"
  value       = confluent_connector.this.status
}