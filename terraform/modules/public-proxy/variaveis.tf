variable "vpc_id" {
  description = "The VPC ID to private link to Confluent Cloud"
  type        = string
}

variable "cluster_hostname" {
  description = "Hostname of the Kafka cluster for proxy configuration"
  type        = string
}

variable "aws_default_zones" {
  description = "List of AWS availability zones and CIDR blocks for subnet creation"
  type = list(object({
    zone = string
    cidr = string
  }))
}

variable "aws_default_ami" {
  description = "Default AMI ID for EC2 instances (Ubuntu 20.04 LTS)"
  type        = string
}

variable "vpc_endpoint_id" {
  description = "VPC Endpoint ID for private link connection"
  type        = string
}

variable "kafka_bootstrap_endpoint" {
  description = "Kafka bootstrap endpoint for proxy configuration"
  type        = string
}

variable "proxy_subnet_cidr" {
  description = "CIDR block for the proxy public subnet"
  type        = string
  default     = "172.30.10.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the proxy"
  type        = string
  default     = "t2.micro"
}