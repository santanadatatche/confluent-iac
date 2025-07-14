variable "cloud" {
  type    = string
  default = "aws"
}

variable "display_name" {
  type = string
}

variable "environment_id" {
  type = string
}

variable "private_link_attachment_id" {
  type = string
}

variable "vpc_endpoint_id" {
  type    = string
  default = null
}

variable "private_endpoint_resource_id" {
  type    = string
  default = null
}

variable "private_service_connect_connection_id" {
  type    = string
  default = null
}