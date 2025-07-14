terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.32.0"
    }
  }
}

resource "confluent_api_key" "this" {
  display_name = var.display_name
  description  = var.description

  owner {
    id          = var.service_account_id
    api_version = var.service_account_api_version
    kind        = "ServiceAccount"
  }

  managed_resource {
    id          = var.kafka_cluster_id
    api_version = var.kafka_cluster_api_version
    kind        = var.kafka_cluster_kind

    environment {
      id = var.environment_id
    }
  }
  disable_wait_for_ready = true
}