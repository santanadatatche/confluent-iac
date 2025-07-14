variable "display_name" {
  description = "Nome do attachment"
  type        = string
}

variable "cloud" {
  description = "Cloud provider (AWS, GCP, AZURE)"
  type        = string
}

variable "region" {
  description = "Região"
  type        = string
}

variable "environment_id" {
  description = "ID do ambiente"
  type        = string
}