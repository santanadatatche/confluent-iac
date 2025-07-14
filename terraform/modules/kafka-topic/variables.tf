variable "kafka_api_key" {
  description = "Kafka API Key"
  type        = string
}

variable "kafka_api_secret" {
  description = "Kafka API Secret"
  type        = string
}

variable "kafka_cluster_id" {
  description = "ID of the Kafka cluster where the topic will be created."
  type        = string
}

variable "kafka_rest_endpoint" {
  description = "REST endpoint of the Kafka cluster"
  type        = string
}

variable "topic_name" {
  description = "Name of the Kafka topic."
  type        = string

  validation {
    condition     = length(var.topic_name) > 0
    error_message = "The topic_name must not be empty."
  }
}

variable "partitions_count" {
  description = "Number of partitions for the Kafka topic."
  type        = number

  validation {
    condition     = var.partitions_count > 0
    error_message = "The partitions_count must be greater than 0."
  }
}

variable "config" {
  description = "Optional map of topic-level configuration (e.g., cleanup.policy, retention.ms)."
  type        = map(string)
  default     = {}
}