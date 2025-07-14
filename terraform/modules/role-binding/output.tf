output "role_binding_id" {
  description = "ID of the role binding"
  value       = confluent_role_binding.this.id
}

output "role_binding_ready" {
  description = "Indicates role binding is ready"
  value       = time_sleep.wait_for_role_binding.id
}