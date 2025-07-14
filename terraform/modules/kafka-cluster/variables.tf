variable "cluster_name" {
  type        = string
  description = "Name of the Kafka cluster"
}

variable "environment_id" {
  type        = string
  description = "ID of the Confluent environment"
}

variable "cloud" {
  type        = string
  description = "Cloud provider (AWS, AZURE, GCP)"
  validation {
    condition     = contains(["AWS", "GCP", "AZURE"], var.cloud)
    error_message = "cloud must be one of: AWS, GCP, AZURE"
  }
}

variable "region" {
  type        = string
  description = "Cloud region"
}

variable "availability" {
  type        = string
  description = "Availability zone type (SINGLE_ZONE or MULTI_ZONE or HIGH)"
  validation {
    condition     = contains(["SINGLE_ZONE", "MULTI_ZONE", "HIGH"], var.availability)
    error_message = "availability must be SINGLE_ZONE or MULTI_ZONE"
  }
}

variable "cluster_type" {
  type        = string
  description = "Cluster type (BASIC, STANDARD, ENTERPRISE, DEDICATED, FREIGHT)"
  validation {
    condition     = contains(["BASIC", "STANDARD", "ENTERPRISE", "DEDICATED", "FREIGHT"], var.cluster_type)
    error_message = "cluster_type must be one of: BASIC, STANDARD, ENTERPRISE, DEDICATED, FREIGHT"
  }
}

variable "cku" {
  type        = number
  description = "Number of CKUs (only for DEDICATED clusters)"
  default     = null
}