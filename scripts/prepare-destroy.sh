#!/bin/bash
# Script to prepare for destroy by removing problematic resources from state

# Configure DNS for Private Link
echo "Configuring DNS for Private Link..."
echo "169.254.169.253 *.us-east-2.aws.private.confluent.cloud" | sudo tee -a /etc/hosts
echo "169.254.169.253 lkc-*.us-east-2.aws.private.confluent.cloud" | sudo tee -a /etc/hosts

# Initialize Terraform
cd terraform/environments/evoluservices
terraform init

# Remove problematic resources from state
echo "Removing problematic resources from state..."
terraform state rm module.kafka_topic.confluent_kafka_topic.this || true
terraform state rm module.kafka_connector_dynamodb_source.confluent_connector.this || true
terraform state rm module.kafka_connector_mysql_source.confluent_connector.this || true
terraform state rm module.kafka_connector_s3_sink.confluent_connector.this || true

# Destroy remaining resources
echo "Destroying remaining resources..."
terraform destroy -auto-approve -var-file=terraform.tfvars