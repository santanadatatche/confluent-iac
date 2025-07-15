output "cluster_id" {
  value = try(
    confluent_kafka_cluster.basic[0].id,
    confluent_kafka_cluster.standard[0].id,
    confluent_kafka_cluster.enterprise[0].id,
    confluent_kafka_cluster.dedicated[0].id,
    confluent_kafka_cluster.freight[0].id
  )
}

output "cluster_name" {
  value = try(
    confluent_kafka_cluster.basic[0].display_name,
    confluent_kafka_cluster.standard[0].display_name,
    confluent_kafka_cluster.enterprise[0].display_name,
    confluent_kafka_cluster.dedicated[0].display_name,
    confluent_kafka_cluster.freight[0].display_name
  )
}

output "bootstrap_endpoint" {
  value = try(
    confluent_kafka_cluster.basic[0].bootstrap_endpoint,
    confluent_kafka_cluster.standard[0].bootstrap_endpoint,
    confluent_kafka_cluster.enterprise[0].bootstrap_endpoint,
    confluent_kafka_cluster.dedicated[0].bootstrap_endpoint,
    confluent_kafka_cluster.freight[0].bootstrap_endpoint
  )
}

output "rest_endpoint" {
  value = try(
    confluent_kafka_cluster.basic[0].rest_endpoint,
    confluent_kafka_cluster.standard[0].rest_endpoint,
    confluent_kafka_cluster.enterprise[0].rest_endpoint,
    confluent_kafka_cluster.dedicated[0].rest_endpoint,
    confluent_kafka_cluster.freight[0].rest_endpoint
  )
}

output "api_version" {
  value = try(
    confluent_kafka_cluster.basic[0].api_version,
    confluent_kafka_cluster.standard[0].api_version,
    confluent_kafka_cluster.enterprise[0].api_version,
    confluent_kafka_cluster.dedicated[0].api_version,
    confluent_kafka_cluster.freight[0].api_version
  )
}

output "kind" {
  value = try(
    confluent_kafka_cluster.basic[0].kind,
    confluent_kafka_cluster.standard[0].kind,
    confluent_kafka_cluster.enterprise[0].kind,
    confluent_kafka_cluster.dedicated[0].kind,
    confluent_kafka_cluster.freight[0].kind
  )
}

output "crn_pattern" {
  value = try(
    confluent_kafka_cluster.basic[0].rbac_crn,
    confluent_kafka_cluster.standard[0].rbac_crn,
    confluent_kafka_cluster.enterprise[0].rbac_crn,
    confluent_kafka_cluster.dedicated[0].rbac_crn,
    confluent_kafka_cluster.freight[0].rbac_crn
  )
}

