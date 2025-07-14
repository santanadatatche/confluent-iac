terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.32.0"
    }
  }
}

resource "confluent_network" "this" {
  display_name = var.display_name
  environment {
    id = var.environment_id
  }

  cloud  = var.cloud
  region = var.region
  zones  = var.zones

  connection_types = var.connection_types

  dynamic "dns_config" {
    for_each = var.dns_resolution != null ? [var.dns_resolution] : []
    content {
      resolution = dns_config.value
    }
  }
}