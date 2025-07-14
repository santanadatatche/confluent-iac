output "acls_ids" {
  description = "Map of ACL resource IDs"
  value       = { for k, v in confluent_kafka_acl.this : k => v.id }
}