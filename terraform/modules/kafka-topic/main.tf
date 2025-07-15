terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.32.0"
    }
  }
}

resource "confluent_kafka_topic" "this" {
  kafka_cluster {
    id = var.kafka_cluster_id
  }
  rest_endpoint    = var.kafka_rest_endpoint
  topic_name       = var.topic_name
  partitions_count = var.partitions_count
  config           = var.config
  
  credentials {
    key    = var.kafka_api_key
    secret = var.kafka_api_secret
  }
  
  lifecycle {
    create_before_destroy = true
  }
}