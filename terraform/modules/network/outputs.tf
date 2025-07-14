output "id" {
  description = "ID da Network criada."
  value       = confluent_network.this.id
}

output "display_name" {
  description = "Nome amigável da Network."
  value       = confluent_network.this.display_name
}