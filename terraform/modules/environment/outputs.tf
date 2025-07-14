output "environment_id" {
  description = "The ID of the created environment"
  value       = confluent_environment.this.id
}