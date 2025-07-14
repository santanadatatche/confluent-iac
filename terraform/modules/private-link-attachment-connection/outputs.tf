output "id" {
  description = "ID da conexão Private Link criada"
  value = try(
    confluent_private_link_attachment_connection.aws[0].id,
    confluent_private_link_attachment_connection.azure[0].id,
    confluent_private_link_attachment_connection.gcp[0].id,
    null
  )
}

output "display_name" {
  description = "Nome de exibição da conexão criada"
  value = try(
    confluent_private_link_attachment_connection.aws[0].display_name,
    confluent_private_link_attachment_connection.azure[0].display_name,
    confluent_private_link_attachment_connection.gcp[0].display_name,
    null
  )
}

output "environment_id" {
  description = "Environment ID associado à conexão Private Link"
  value = try(
    confluent_private_link_attachment_connection.aws[0].environment[0].id,
    confluent_private_link_attachment_connection.azure[0].environment[0].id,
    confluent_private_link_attachment_connection.gcp[0].environment[0].id,
    null
  )
}