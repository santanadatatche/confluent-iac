data "external" "my_public_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

locals {
  cluster_hostname = var.cluster_hostname
}
