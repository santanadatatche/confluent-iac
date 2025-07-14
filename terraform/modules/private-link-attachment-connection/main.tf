terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.32.0"
    }
  }
}

resource "confluent_private_link_attachment_connection" "aws" {
  count        = lower(var.cloud) == "aws" ? 1 : 0
  display_name = var.display_name

  environment {
    id = var.environment_id
  }

  private_link_attachment {
    id = var.private_link_attachment_id
  }

  aws {
    vpc_endpoint_id = var.vpc_endpoint_id
  }
}

resource "confluent_private_link_attachment_connection" "azure" {
  count        = lower(var.cloud) == "azure" ? 1 : 0
  display_name = var.display_name

  environment {
    id = var.environment_id
  }

  private_link_attachment {
    id = var.private_link_attachment_id
  }

  azure {
    private_endpoint_resource_id = var.private_endpoint_resource_id
  }
}

resource "confluent_private_link_attachment_connection" "gcp" {
  count        = lower(var.cloud) == "gcp" ? 1 : 0
  display_name = var.display_name

  environment {
    id = var.environment_id
  }

  private_link_attachment {
    id = var.private_link_attachment_id
  }

  gcp {
    private_service_connect_connection_id = var.private_service_connect_connection_id
  }
}