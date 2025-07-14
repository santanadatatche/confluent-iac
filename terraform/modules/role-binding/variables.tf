variable "service_account_id" {
  description = "ID of the Service Account"
  type        = string
}

variable "role_name" {
  description = "Description of the role"
  type        = string
  default     = ""
}

variable "crn_pattern" {
  description = "crn_pattern of the Kafka Cluster"
  type        = string
  default     = ""
}