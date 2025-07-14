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
  region = var.region
  # AWS credentials should be set via environment variables:
  # export AWS_ACCESS_KEY_ID="your-access-key"
  # export AWS_SECRET_ACCESS_KEY="your-secret-key"
  # Note: AWS region is the same as Confluent region
}

