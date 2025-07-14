terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.32.0"
    }
  }
}

resource "confluent_kafka_cluster" "basic" {
  count = var.cluster_type == "BASIC" ? 1 : 0

  display_name = var.cluster_name
  cloud        = var.cloud
  region       = var.region
  availability = var.availability

  environment {
    id = var.environment_id
  }

  basic {}

}

resource "confluent_kafka_cluster" "standard" {
  count = var.cluster_type == "STANDARD" ? 1 : 0

  display_name = var.cluster_name
  cloud        = var.cloud
  region       = var.region
  availability = var.availability

  environment {
    id = var.environment_id
  }

  standard {}

}


resource "confluent_kafka_cluster" "enterprise" {
  count = var.cluster_type == "ENTERPRISE" ? 1 : 0

  display_name = var.cluster_name
  cloud        = var.cloud
  region       = var.region
  availability = var.availability

  environment {
    id = var.environment_id
  }

  enterprise {}

}

resource "confluent_kafka_cluster" "dedicated" {
  count = var.cluster_type == "DEDICATED" ? 1 : 0

  display_name = var.cluster_name
  cloud        = var.cloud
  region       = var.region
  availability = var.availability

  environment {
    id = var.environment_id
  }

  dedicated {
    cku = var.cku
  }

}

resource "confluent_kafka_cluster" "freight" {
  count = var.cluster_type == "FREIGHT" ? 1 : 0

  display_name = var.cluster_name
  cloud        = var.cloud
  region       = var.region
  availability = var.availability

  environment {
    id = var.environment_id
  }

  freight {}

}