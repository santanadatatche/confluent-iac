output "vpc_endpoint_id" {
  value = aws_vpc_endpoint.privatelink.id
}

output "flink_private_endpoint" {
  description = "Flink private endpoint URL"
  value = "flink.${var.dns_domain}"
}

output "aws_privatelink_endpoint_dns_entries" {
  description = "DNS entries for /etc/hosts to enable Private Link access"
  value = "# Execute o script get_vpc_endpoint_ips.sh para obter as entradas DNS"
}