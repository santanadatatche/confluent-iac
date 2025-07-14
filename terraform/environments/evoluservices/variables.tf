
##########################
# 📦 AWS Credential
##########################
variable "aws_account_id" {
  type        = string
  description = "AWS account ID for Private Link usage"
}


variable "aws_default_zones" {
  type = list(object({
    zone = string
    cidr = string
  }))
  default = [
    { "zone" = "us-east-2a", cidr = "10.0.0.0/16" },
    { "zone" = "us-east-2b", cidr = "10.0.1.0/16" },
    { "zone" = "us-east-2c", cidr = "10.0.2.0/16" }
  ]
  description = "Lista de zonas de disponibilidade e CIDRs utilizados para criação de subnets em uma VPC padrão."
}

variable "aws_default_ami" {
  type        = string
  default     = "ami-0f5daaa3a7fb3378b" #us-east-2 "ami-036f48ec20249562a" # sa-east-1
  description = "AMI padrão utilizada para instância EC2. Altere conforme a região e a necessidade do sistema operacional."
}

##########################
# 🌍 Environment Settings
##########################
variable "environment_name" {
  type        = string
  description = "Name of the Confluent environment"
}

##########################
# ☁️ Kafka Cluster Settings
##########################
variable "availability" {
  type        = string
  description = "Cluster availability (SINGLE_ZONE or MULTI_ZONE)"
}

variable "cloud" {
  type        = string
  description = "Cloud provider for the Kafka cluster (e.g., aws, azure, gcp)"
}

variable "cluster_name" {
  type        = string
  description = "Name of the Kafka cluster"
}

variable "cluster_type" {
  type        = string
  description = "Type of Kafka cluster (e.g., BASIC, STANDARD, DEDICATED)"
}

variable "cku" {
  type        = number
  description = "Number of CKUs for dedicated clusters"
  default     = null
}

variable "region" {
  type        = string
  description = "Region in which to deploy the Kafka cluster"
}

##########################
# 🔐 Service Account
##########################
variable "service_account_name" {
  type        = string
  description = "Name of the Service Account used by app connectors"
}

variable "service_account_description" {
  type        = string
  description = "Description of the Service Account used by app connectors"
}

##########################
# 🔐 Role Binding
##########################
variable "role_name" {
  type        = string
  description = "Name of the Role Binding used by Service Account"
}


##########################
# 🔐 API Key (App Connectors)
##########################
variable "api_key_name" {
  type        = string
  description = "Name of the API key used by app connectors"
}

variable "api_key_description" {
  type        = string
  description = "Description of the API key used by app connectors"
}

##########################
# 📡 Topic Configuration
##########################
variable "topic_config" {
  type        = map(string)
  description = "Map of topic-level configurations"
}

variable "topic_name" {
  type        = string
  description = "Name of the topic to be created"
}

variable "topic_partitions" {
  type        = number
  description = "Number of partitions for the topic"
}

##########################
# 🔌 Private Link (AWS, Azure, GCP)
##########################
variable "vpc_id" {
  description = "The VPC ID to private link to Confluent Cloud"
  type        = string
}

variable "subnets_to_privatelink" {
  description = "A map of Zone ID to Subnet ID (ie: {\"use1-az1\" = \"subnet-abcdef0123456789a\", ...})"
  type        = map(string)
}

variable "platt_display_name" {
  type        = string
  description = "Privatelink attachment name"
}

variable "plattc_display_name" {
  type        = string
  description = "Privatelink attachment connection name"
}
##########################
# 🔐 NonSensitive Connector Configs
##########################
variable "dynamodb_source_config_nonsensitive" {
  type        = map(string)
  description = "Sensitive config for DynamoDB connector"
  default     = {}
}

variable "mysql_source_config_nonsensitive" {
  type        = map(string)
  description = "Sensitive config for MySQL Debezium connector"
  default     = {}
}

variable "s3_sink_config_nonsensitive" {
  type        = map(string)
  description = "Sensitive config for S3 sink connector"
  default     = {}
}

##########################
# 🔐 Sensitive Connector Configs
##########################
variable "dynamodb_source_config_sensitive" {
  type        = map(string)
  sensitive   = true
  description = "Sensitive config for DynamoDB connector"
  default     = {}
}

variable "mysql_source_config_sensitive" {
  type        = map(string)
  sensitive   = true
  description = "Sensitive config for MySQL Debezium connector"
  default     = {}
}

variable "s3_sink_config_sensitive" {
  type        = map(string)
  sensitive   = true
  description = "Sensitive config for S3 sink connector"
  default     = {}
}

##########################
# 🔐 Individual Sensitive Variables
##########################
variable "mysql_password" {
  type        = string
  sensitive   = true
  description = "MySQL database password"
}

variable "connector_aws_access_key" {
  type        = string
  sensitive   = true
  description = "AWS Access Key for connectors"
}

variable "connector_aws_secret_key" {
  type        = string
  sensitive   = true
  description = "AWS Secret Key for connectors"
}

variable "connector_dynamodb_access_key" {
  type        = string
  sensitive   = true
  description = "AWS Access Key for DynamoDB connector"
}

variable "connector_dynamodb_secret_key" {
  type        = string
  sensitive   = true
  description = "AWS Secret Key for DynamoDB connector"
}