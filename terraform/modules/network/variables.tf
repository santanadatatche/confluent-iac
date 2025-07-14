variable "environment_id" {
  type        = string
  description = "ID do ambiente Confluent."
}

variable "display_name" {
  type        = string
  description = "Nome amigável da Network."
}

variable "cloud" {
  type        = string
  description = "Cloud provider (AWS, GCP, AZURE)."
}

variable "region" {
  type        = string
  description = "Região da Cloud."
}

variable "zones" {
  type        = list(string)
  description = "Zonas de disponibilidade."
  default     = []
}

variable "connection_types" {
  type        = list(string)
  description = "Tipos de conexão: PUBLIC ou PRIVATE."
}

variable "dns_resolution" {
  type        = string
  description = "Configuração de DNS: PRIVATE ou PUBLIC."
  default     = null
}