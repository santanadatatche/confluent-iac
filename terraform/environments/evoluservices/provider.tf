terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.17.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.32.0"
    }
  }
}

provider "confluent" {
  # Confluent credentials should be set via environment variables:
  # export CONFLUENT_CLOUD_API_KEY="your-api-key"
  # export CONFLUENT_CLOUD_API_SECRET="your-api-secret"
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

