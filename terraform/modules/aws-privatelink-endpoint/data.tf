data "aws_network_interface" "privatelink" {
  count = length(aws_vpc_endpoint.privatelink.network_interface_ids) > 0 ? 1 : 0
  id    = aws_vpc_endpoint.privatelink.network_interface_ids[0]
}