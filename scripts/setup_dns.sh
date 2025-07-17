#!/bin/bash
# Script to configure DNS for Confluent Cloud Private Link in GitHub Actions
# Based on https://docs.confluent.io/cloud/current/networking/ccloud-console-access.html

# Get the cluster ID from arguments or state
CLUSTER_ID=$1
if [ -z "$CLUSTER_ID" ]; then
  echo "Getting cluster ID from terraform state..."
  CLUSTER_ID=$(terraform -chdir=terraform/environments/evoluservices state show module.kafka_cluster.confluent_kafka_cluster.enterprise[0] | grep id | head -1 | awk '{print $3}' | tr -d '"')
fi

echo "Cluster ID: $CLUSTER_ID"

# Configure /etc/hosts to use AWS DNS resolver
echo "Configuring DNS for Confluent Cloud Private Link..."
echo "169.254.169.253 $CLUSTER_ID.us-east-2.aws.private.confluent.cloud" | sudo tee -a /etc/hosts
echo "169.254.169.253 flink.us-east-2.aws.private.confluent.cloud" | sudo tee -a /etc/hosts

# Verify the entries
echo "Verifying /etc/hosts entries:"
cat /etc/hosts

# Test DNS resolution
echo "Testing DNS resolution:"
nslookup $CLUSTER_ID.us-east-2.aws.private.confluent.cloud || true