variable "display_name" {
  description = "Display name of the API Key"
  type        = string
}

variable "description" {
  description = "Description of the API Key"
  type        = string
  default     = ""
}

variable "service_account_id" {
  description = "ID of the Service Account owner"
  type        = string
}

variable "service_account_api_version" {
  description = "API Version of the Service Account owner"
  type        = string
}

variable "kafka_cluster_id" {
  description = "ID of the Kafka Cluster where this API Key will be used"
  type        = string
}

variable "kafka_cluster_api_version" {
  description = "API Version of the Kafka Cluster where this API Key will be used"
  type        = string
}

variable "kafka_cluster_kind" {
  description = "Kind of the Kafka Cluster where this API Key will be used"
  type        = string
}

variable "environment_id" {
  description = "ID of the Confluent Environment"
  type        = string
}