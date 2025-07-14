variable "kafka_cluster_id" {
  description = "ID of the Kafka Cluster where the ACLs will be applied"
  type        = string
}

variable "kafka_api_key" {
  description = "Kafka API Key for authentication"
  type        = string
  sensitive   = true
}

variable "kafka_api_secret" {
  description = "Kafka API Secret for authentication"
  type        = string
  sensitive   = true
}

variable "acls" {
  description = <<EOT
Map of ACL definitions.
Example:
{
  create_topics = {
    resource_type = "Cluster"
    resource_name = "kafka-cluster"
    pattern_type  = "LITERAL"
    principal     = "User:sa-abc123"
    host          = "*"
    operation     = "CREATE"
    permission    = "ALLOW"
    rest_endpoint = module.kafka_cluster.rest_endpoint
  }
  read_orders = {
    resource_type = "Topic"
    resource_name = "orders"
    pattern_type  = "LITERAL"
    principal     = "User:sa-abc123"
    host          = "*"
    operation     = "READ"
    permission    = "ALLOW"
    rest_endpoint = module.kafka_cluster.rest_endpoint
  }
}
EOT
  type = map(object({
    resource_type = string
    resource_name = string
    pattern_type  = string
    principal     = string
    host          = string
    operation     = string
    permission    = string
    rest_endpoint = string
  }))
}