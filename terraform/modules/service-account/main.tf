terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.32.0"
    }
  }
}

resource "confluent_service_account" "this" {
  display_name = var.display_name
  description  = var.description
}