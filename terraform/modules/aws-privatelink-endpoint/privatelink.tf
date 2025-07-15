terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.17.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.32.0"
    }
  }
}

data "aws_vpc" "privatelink" {
  id = var.vpc_id
}

data "aws_availability_zone" "privatelink" {
  for_each = var.subnets_to_privatelink
  zone_id = each.key
}

locals {
  network_id = split(".", var.dns_domain)[0]
}

resource "aws_security_group" "privatelink" {
  # Ensure that SG is unique, so that this module can be used multiple times within a single VPC
  name = "ccloud-privatelink_${local.network_id}_${var.vpc_id}"
  description = "Confluent Cloud Private Link minimal security group for ${var.dns_domain} in ${var.vpc_id}"
  vpc_id = data.aws_vpc.privatelink.id

  ingress {
    # only necessary if redirect support from http/https is desired
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  ingress {
    from_port = 9092
    to_port = 9092
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint" "privatelink" {
  vpc_id = data.aws_vpc.privatelink.id
  service_name = var.privatelink_service_name
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.privatelink.id,
  ]

  subnet_ids = [for zone, subnet_id in var.subnets_to_privatelink: subnet_id]
  private_dns_enabled = false
}

# Try to find existing hosted zone first
data "aws_route53_zone" "existing" {
  name         = var.dns_domain
  private_zone = true
  vpc_id       = data.aws_vpc.privatelink.id
}



# Create hosted zone only if it doesn't exist
resource "aws_route53_zone" "privatelink" {
  count = data.aws_route53_zone.existing.zone_id == null ? 1 : 0
  name = var.dns_domain

  vpc {
    vpc_id = data.aws_vpc.privatelink.id
  }
}

# Use existing zone if available, otherwise use created zone
locals {
  zone_id = data.aws_route53_zone.existing.zone_id != null ? data.aws_route53_zone.existing.zone_id : aws_route53_zone.privatelink[0].zone_id
  zone_name = data.aws_route53_zone.existing.name != null ? data.aws_route53_zone.existing.name : aws_route53_zone.privatelink[0].name
}

resource "aws_route53_record" "privatelink" {
  count = length(var.subnets_to_privatelink) == 1 ? 0 : 1
  zone_id = local.zone_id
  name = "*.${local.zone_name}"
  type = "CNAME"
  ttl  = "60"
  records = [
    aws_vpc_endpoint.privatelink.dns_entry[0]["dns_name"]
  ]
  
  lifecycle {
    ignore_changes = [records]
  }
}

locals {
  endpoint_prefix = split(".", aws_vpc_endpoint.privatelink.dns_entry[0]["dns_name"])[0]
}

resource "aws_route53_record" "privatelink-zonal" {
  for_each = var.subnets_to_privatelink

  zone_id = local.zone_id
  name = length(var.subnets_to_privatelink) == 1 ? "*" : "*.${each.key}"
  type = "CNAME"
  ttl  = "60"
  records = [
    format("%s-%s%s",
      local.endpoint_prefix,
      data.aws_availability_zone.privatelink[each.key].name,
      replace(aws_vpc_endpoint.privatelink.dns_entry[0]["dns_name"], local.endpoint_prefix, "")
    )
  ]
}

# Flink DNS records already exist - skipping creation
# The existing records will be used for Flink connectivity

output "vpc_endpoint_id" {
  value = aws_vpc_endpoint.privatelink.id
}

output "flink_private_endpoint" {
  description = "Flink private endpoint URL"
  value = "flink.${var.dns_domain}"
}