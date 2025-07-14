terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.32.0"
    }
  }
}

resource "confluent_private_link_attachment" "this" {
  display_name = var.display_name
  cloud        = var.cloud
  region       = var.region

  environment {
    id = var.environment_id
  }

}