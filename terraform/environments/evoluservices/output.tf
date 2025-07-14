output "environment_id" {
  description = "ID do ambiente criado"
  value       = module.environment.environment_id
}

output "environment_name" {
  description = "Nome do ambiente criado"
  value       = var.environment_name
}

output "kafka_cluster_id" {
  description = "ID do Kafka Cluster"
  value       = module.kafka_cluster.cluster_id
}

output "kafka_cluster_kind" {
  description = "Tipo do Kafka Cluster"
  value       = module.kafka_cluster.kind
}

output "kafka_cluster_api_version" {
  description = "API Version do Kafka Cluster"
  value       = module.kafka_cluster.api_version
}

output "kafka_bootstrap_endpoint" {
  description = "Kafka Bootstrap Endpoint (SSL)"
  value       = module.kafka_cluster.bootstrap_endpoint
}

output "kafka_rest_endpoint" {
  description = "Kafka REST Endpoint"
  value       = module.kafka_cluster.rest_endpoint
}
/*
output "network_id" {
description = "ID da Network criada."
  value       = module.network.id
}

output "network_display_name" {
description = "Nome amigável da Network."
  value       = module.network.display_name
}
*/
output "platt_id" {
  value       = module.private_link_attachment.id
  description = "ID of the Private Link attachment."
}

output "platt_display_name" {
  value       = module.private_link_attachment.display_name
  description = "Display name of the Private Link attachment."
}

output "platt_dns_domain" {
  value       = module.private_link_attachment.dns_domain
  description = "DNS domain of the Private Link attachment."
}

output "platt_aws" {
  value       = module.private_link_attachment.aws[0].vpc_endpoint_service_name
  description = "AWS values  of the Private Link attachment"
}

output "plattc_id" {
  value       = module.private_link_attachment_connection.id
  description = "ID of the Private Link attachment."
}

output "plattc_display_name" {
  value       = module.private_link_attachment_connection.display_name
  description = "Display name of the Private Link attachment."
}

output "vpc_endpoint_id"{
  value       = module.privatelink.vpc_endpoint_id
  description = "VPC Endpoint ID"
}

output "proxy_public_ip" {
  description = "IP público do proxy NGINX"
  value       = module.proxy.proxy_public_ip
}

output "proxy_ssh_command" {
  description = "Comando SSH para acessar o proxy"
  value       = module.proxy.ssh_command
}

output "proxy_diagnosis_command" {
  description = "Comando para diagnosticar o proxy"
  value       = module.proxy.diagnosis_command
}

output "service_account_manager_id" {
  description = "ID do Service Account usado para gerenciar o cluster"
  value       = module.service_account_manager.id
}

output "service_account_manager_api_key" {
  description = "API Key do Service Account Manager (⚠️ sensível)"
  sensitive   = true
  value       = module.api_key_manager.kafka_api_key
}

output "service_account_manager_api_secret" {
  description = "API Secret do Service Account Manager (⚠️ sensível)"
  sensitive   = true
  value       = module.api_key_manager.kafka_api_secret
}
/*
output "topic_name" {
  description = "Nome do tópico criado"
  value       = module.kafka_topic.topic_name
}
*/
output "mysql_connector_name" {
  description = "Nome do conector MySQL (se criado)"
  value       = try(module.kafka_connector_mysql_source.connector_name, null)
}
/*
output "s3_connector_name" {
  description = "Nome do conector S3 (se criado)"
  value       = try(module.kafka_connector_s3_sink.connector_name, null)
}
*/
output "dynamodb_connector_name" {
  description = "Nome do conector DynamoDB (se criado)"
  value       = try(module.kafka_connector_dynamodb_source.connector_name, null)
}

output "hosts_command" {
  description = "Comando para configurar /etc/hosts"
  value       = "sudo bash -c 'echo \"${module.proxy.proxy_public_ip} ${regex("(.*):", module.kafka_cluster.bootstrap_endpoint)[0]}\" >> /etc/hosts && echo \"${module.proxy.proxy_public_ip} flink.${module.private_link_attachment.dns_domain}\" >> /etc/hosts'"
}

output "topic_name" {
  description = "Nome do tópico criado"
  value       = try(module.kafka_topic.topic_name, null)
}

output "s3_connector_name" {
  description = "Nome do conector S3 (se criado)"
  value       = try(module.kafka_connector_s3_sink.connector_name, null)
}

output "role_binding_id" {
  description = "ID do role binding principal"
  value       = module.role_binding.role_binding_id
}

output "role_binding_topic_id" {
  description = "ID do role binding para tópicos"
  value       = module.role_binding_topic.role_binding_id
}

output "proxy_security_group_id" {
  description = "ID do security group do proxy"
  value       = module.proxy.security_group_id
}

output "proxy_subnet_id" {
  description = "ID da subnet pública do proxy"
  value       = module.proxy.subnet_id
}

output "cluster_crn_pattern" {
  description = "CRN pattern do cluster Kafka"
  value       = module.kafka_cluster.crn_pattern
}

output "environment_crn" {
  description = "CRN do ambiente Confluent"
  value       = "crn://confluent.cloud/environment=${module.environment.environment_id}"
}

output "flink_private_endpoint" {
  description = "Flink private endpoint URL"
  value       = module.privatelink.flink_private_endpoint
}

output "flink_public_endpoint" {
  description = "Flink public endpoint URL"
  value       = "flink.${var.region}.${lower(var.cloud)}.confluent.cloud"
}