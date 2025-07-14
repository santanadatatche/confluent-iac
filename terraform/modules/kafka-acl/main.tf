terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.32.0"
    }
  }
}

resource "confluent_kafka_acl" "this" {
  for_each = var.acls

  kafka_cluster {
    id = var.kafka_cluster_id
  }

  resource_type = each.value.resource_type
  resource_name = each.value.resource_name
  pattern_type  = each.value.pattern_type
  principal     = each.value.principal
  host          = each.value.host
  operation     = each.value.operation
  permission    = each.value.permission
  rest_endpoint = each.value.rest_endpoint

  credentials {
    key    = var.kafka_api_key
    secret = var.kafka_api_secret
  }
}