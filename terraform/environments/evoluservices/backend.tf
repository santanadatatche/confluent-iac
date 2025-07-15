terraform {
  backend "s3" {
    bucket = "confluent-iac-terraform-state"
    key    = "staging/terraform.tfstate"
    region = "us-east-2"
  }
}