variable "environment_id" {
  type        = string
  description = "Environment ID where Private Link Access will be created."
}

variable "display_name" {
  type        = string
  description = "Nome da conexão Private Link"
}

variable "network_id" {
  type        = string
  description = "Network ID where Private Link Access will be created."
}

variable "aws_account" {
  type        = string
  description = "AWS account number to grant access (only for AWS)."
}