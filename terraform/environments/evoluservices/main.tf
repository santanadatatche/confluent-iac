module "environment" {
  source = "../../modules/environment"
  display_name = var.environment_name
}

module "kafka_cluster" {
  source = "../../modules/kafka-cluster"
  cluster_name    = var.cluster_name
  cluster_type    = var.cluster_type
  environment_id  = module.environment.environment_id
  availability    = var.availability
  cloud           = var.cloud
  region          = var.region
  cku            = var.cku
  depends_on = [
    module.environment
  ]
}

module "private_link_attachment" {
  source = "../../modules/private-link-attachment"
  display_name   = var.platt_display_name
  cloud          = var.cloud
  region         = var.region
  environment_id = module.environment.environment_id
}

module "privatelink" {
  source                   = "../../modules/aws-privatelink-endpoint"
  vpc_id                   = var.vpc_id
  privatelink_service_name = module.private_link_attachment.aws[0].vpc_endpoint_service_name
  dns_domain               = module.private_link_attachment.dns_domain
  subnets_to_privatelink   = var.subnets_to_privatelink
}

module "private_link_attachment_connection" {
  source                     = "../../modules/private-link-attachment-connection"
  environment_id             = module.environment.environment_id
  private_link_attachment_id = module.private_link_attachment.id
  display_name               = var.plattc_display_name
  cloud                      = var.cloud
  vpc_endpoint_id            =  module.privatelink.vpc_endpoint_id
  
  depends_on = [
    module.private_link_attachment
  ] 
}

module "proxy" {
  source = "../../modules/public-proxy"
  vpc_id = var.vpc_id
  aws_default_zones  = var.aws_default_zones
  aws_default_ami  = var.aws_default_ami
  cluster_hostname = regex("(.*):", module.kafka_cluster.bootstrap_endpoint)[0]
  kafka_bootstrap_endpoint = module.kafka_cluster.bootstrap_endpoint
  vpc_endpoint_id = module.privatelink.vpc_endpoint_id
  depends_on = [
    module.kafka_cluster,
    module.private_link_attachment_connection,
    module.privatelink
  ] 
}

module "service_account_manager" {
  source = "../../modules/service-account"
  display_name = var.service_account_name
  description  = var.service_account_description
}

module "role_binding" {
  source = "../../modules/role-binding"
  service_account_id     = "User:${module.service_account_manager.id}"
  role_name   = var.role_name
  crn_pattern = module.kafka_cluster.crn_pattern
}

# Additional role binding for topic management
module "role_binding_topic" {
  source = "../../modules/role-binding"
  service_account_id     = "User:${module.service_account_manager.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${module.kafka_cluster.crn_pattern}/kafka=${module.kafka_cluster.cluster_id}/topic=*"
  
  depends_on = [module.kafka_cluster]
}

module "api_key_manager" {
  source = "../../modules/api-key"
  display_name        = var.api_key_name
  description         = var.api_key_description
  service_account_id  = module.service_account_manager.id
  service_account_api_version  = module.service_account_manager.api_version
  kafka_cluster_id    = module.kafka_cluster.cluster_id
  kafka_cluster_api_version    = module.kafka_cluster.api_version
  kafka_cluster_kind    = module.kafka_cluster.kind
  environment_id      = module.environment.environment_id
}

# Wait for proxy to be ready before creating topics (only when proxy exists)
resource "null_resource" "wait_for_proxy" {
  count = can(module.proxy.proxy_ready) ? 1 : 0
  depends_on = [module.proxy]
  
  provisioner "local-exec" {
    command = "echo 'Proxy is ready: ${module.proxy.proxy_ready}'"
  }
}

# Configure DNS automatically (only when proxy exists)
resource "null_resource" "configure_hosts" {
  count = can(module.proxy.proxy_public_ip) ? 1 : 0
  depends_on = [null_resource.wait_for_proxy]
  
  provisioner "local-exec" {
    command = <<-EOF
      # Try to configure hosts automatically
      if command -v sudo >/dev/null 2>&1; then
        # Remove existing entries
        sudo sed -i '' '/${regex("(.*):", module.kafka_cluster.bootstrap_endpoint)[0]}/d' /etc/hosts 2>/dev/null || true
        sudo sed -i '' '/flink.${module.private_link_attachment.dns_domain}/d' /etc/hosts 2>/dev/null || true
        # Add new entries
        echo '${module.proxy.proxy_public_ip} ${regex("(.*):", module.kafka_cluster.bootstrap_endpoint)[0]}' | sudo tee -a /etc/hosts
        echo '${module.proxy.proxy_public_ip} flink.${module.private_link_attachment.dns_domain}' | sudo tee -a /etc/hosts
        echo "DNS configured successfully for Kafka and Flink"
      else
        echo "WARNING: sudo not available. Manual DNS configuration required:"
        echo "echo '${module.proxy.proxy_public_ip} ${regex("(.*):", module.kafka_cluster.bootstrap_endpoint)[0]}' >> /etc/hosts"
        echo "echo '${module.proxy.proxy_public_ip} flink.${module.private_link_attachment.dns_domain}' >> /etc/hosts"
      fi
    EOF
  }
  
  triggers = {
    proxy_ip = module.proxy.proxy_public_ip
    cluster_host = regex("(.*):", module.kafka_cluster.bootstrap_endpoint)[0]
    flink_host = "flink.${module.private_link_attachment.dns_domain}"
  }
}

# Wait for role binding to be ready
resource "null_resource" "wait_for_permissions" {
  depends_on = [module.role_binding]
  
  provisioner "local-exec" {
    command = "echo 'Role binding ready: ${module.role_binding.role_binding_ready}'"
  }
}

module "kafka_topic" {
  source = "../../modules/kafka-topic"
  
  kafka_api_key       = module.api_key_manager.kafka_api_key
  kafka_api_secret    = module.api_key_manager.kafka_api_secret
  kafka_cluster_id     = module.kafka_cluster.cluster_id
  # Use public endpoint for GitHub Actions compatibility
  kafka_rest_endpoint  = replace(module.kafka_cluster.rest_endpoint, ".aws.private.confluent.cloud", ".aws.confluent.cloud")
  topic_name           = var.topic_name
  partitions_count     = var.topic_partitions
  config               = var.topic_config

  depends_on = [
    module.api_key_manager,
    module.role_binding_topic
  ]
}

module "kafka_connector_s3_sink" {
  source = "../../modules/kafka-connector"
  environment_id   = module.environment.environment_id
  kafka_cluster_id = module.kafka_cluster.cluster_id

  config_nonsensitive = merge(
    {
      "topics"                                   = module.kafka_topic.topic_name
      "kafka.service.account.id" = module.service_account_manager.id

    },
    var.s3_sink_config_nonsensitive
  )

  config_sensitive = {
    "aws.access.key.id"     = var.connector_aws_access_key
    "aws.secret.access.key" = var.connector_aws_secret_key
  }

  depends_on = [
    module.kafka_topic,
    module.api_key_manager
  ]
}

module "kafka_connector_dynamodb_source" {
  source = "../../modules/kafka-connector"

  environment_id   = module.environment.environment_id
  kafka_cluster_id = module.kafka_cluster.cluster_id

  config_nonsensitive = merge(
    {
      "kafka.api.key"       = module.api_key_manager.kafka_api_key
      "kafka.api.secret"    = module.api_key_manager.kafka_api_secret
    },
    var.dynamodb_source_config_nonsensitive
  )
  config_sensitive = {
    "aws.access.key.id"     = var.connector_dynamodb_access_key
    "aws.secret.access.key" = var.connector_dynamodb_secret_key
  }



  depends_on = [
    module.api_key_manager
  ]
}

module "kafka_connector_mysql_source" {
  source = "../../modules/kafka-connector"

  environment_id   = module.environment.environment_id
  kafka_cluster_id = module.kafka_cluster.cluster_id

  config_nonsensitive = merge(
    {
      "kafka.api.key"       = module.api_key_manager.kafka_api_key
      "kafka.api.secret"    = module.api_key_manager.kafka_api_secret
    },
    var.mysql_source_config_nonsensitive
  )
  config_sensitive = {
    "database.password" = var.mysql_password
  }
  

  
  depends_on = [
    module.api_key_manager
  ]
}