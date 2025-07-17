locals {
  # Converter o conjunto (set) em uma lista para poder acessar elementos específicos
  network_interface_ids = tolist(aws_vpc_endpoint.privatelink.network_interface_ids)
}

data "aws_network_interface" "privatelink" {
  count = length(local.network_interface_ids) > 0 ? 1 : 0
  id    = local.network_interface_ids[0]
}