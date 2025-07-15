output "dns_configured" {
  value = "${var.cluster_host} -> ${var.proxy_ip}"
}