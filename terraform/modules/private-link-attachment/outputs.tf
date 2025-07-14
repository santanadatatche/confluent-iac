output "id" {
  value       = confluent_private_link_attachment.this.id
  description = "ID of the Private Link attachment."
}

output "display_name" {
  value       = confluent_private_link_attachment.this.display_name
  description = "Display name of the Private Link attachment."
}

output "dns_domain" {
  value       = confluent_private_link_attachment.this.dns_domain
  description = "DNS domain of the Private Link attachment."
}

output "aws" {
  value       = confluent_private_link_attachment.this.aws
  description = "AWS values  of the Private Link attachment"
}