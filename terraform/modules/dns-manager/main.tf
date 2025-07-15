resource "null_resource" "dns_manager" {
  triggers = {
    proxy_ip = var.proxy_ip
    cluster_host = var.cluster_host
    flink_host = var.flink_host
  }

  # Configure DNS on creation
  provisioner "local-exec" {
    command = <<-EOF
      # Remove existing entries
      sudo sed -i '' '/${var.cluster_host}/d' /etc/hosts 2>/dev/null || true
      sudo sed -i '' '/${var.flink_host}/d' /etc/hosts 2>/dev/null || true
      
      # Add new entries
      echo '${var.proxy_ip} ${var.cluster_host}' | sudo tee -a /etc/hosts
      echo '${var.proxy_ip} ${var.flink_host}' | sudo tee -a /etc/hosts
      
      echo "DNS configured: ${var.cluster_host} -> ${var.proxy_ip}"
    EOF
  }

  # Clean up DNS on destruction
  provisioner "local-exec" {
    when = destroy
    command = <<-EOF
      # Remove entries added by Terraform
      sudo sed -i '' '/${self.triggers.cluster_host}/d' /etc/hosts 2>/dev/null || true
      sudo sed -i '' '/${self.triggers.flink_host}/d' /etc/hosts 2>/dev/null || true
      
      echo "DNS cleanup completed"
    EOF
  }
}