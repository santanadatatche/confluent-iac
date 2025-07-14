variable "environment_id" {
  description = "ID of the Confluent environment"
  type        = string
}

variable "kafka_cluster_id" {
  description = "ID of the Kafka cluster"
  type        = string
}

variable "config_nonsensitive" {
  description = "Map of nonsensitive connector configuration properties"
  type        = map(string)
  default     = {}
}

variable "config_sensitive" {
  description = "Sensitive connector configuration (e.g., AWS credentials)"
  type        = map(string)
  default     = {}
}
