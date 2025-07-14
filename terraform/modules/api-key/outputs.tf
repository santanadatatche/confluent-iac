output "kafka_api_key" {
  description = "Kafka API Key"
  value       = confluent_api_key.this.id
  sensitive   = true
}

output "kafka_api_secret" {
  description = "Kafka API Secret"
  value       = confluent_api_key.this.secret
  sensitive   = true
}