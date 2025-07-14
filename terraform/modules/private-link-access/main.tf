terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.32.0"
    }
  }
}

resource "confluent_private_link_access" "this" {
  display_name = var.display_name
  environment {
    id = var.environment_id
  }

  network {
    id = var.network_id
  }

  aws {
    account = var.aws_account
  }
}