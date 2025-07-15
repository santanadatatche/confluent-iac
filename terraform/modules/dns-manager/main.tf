resource "null_resource" "dns_manager" {
  triggers = {
    proxy_ip = var.proxy_ip
    cluster_host = var.cluster_host
    flink_host = var.flink_host
  }

  # Configure DNS - works locally and in CI
  provisioner "local-exec" {
    command = <<-EOF
      # Check if running in CI/CD
      if [ "$GITHUB_ACTIONS" = "true" ]; then
        echo "Running in GitHub Actions - DNS configuration not needed"
        exit 0
      fi
      
      # Local environment - configure hosts
      if command -v sudo >/dev/null 2>&1; then
        sudo sed -i '' '/${var.cluster_host}/d' /etc/hosts 2>/dev/null || true
        sudo sed -i '' '/${var.flink_host}/d' /etc/hosts 2>/dev/null || true
        echo '${var.proxy_ip} ${var.cluster_host}' | sudo tee -a /etc/hosts
        echo '${var.proxy_ip} ${var.flink_host}' | sudo tee -a /etc/hosts
        echo "DNS configured: ${var.cluster_host} -> ${var.proxy_ip}"
      else
        echo "Manual DNS required: ${var.proxy_ip} ${var.cluster_host}"
      fi
    EOF
  }

  # Clean up DNS on destruction
  provisioner "local-exec" {
    when = destroy
    command = <<-EOF
      if [ "$GITHUB_ACTIONS" != "true" ] && command -v sudo >/dev/null 2>&1; then
        sudo sed -i '' '/${self.triggers.cluster_host}/d' /etc/hosts 2>/dev/null || true
        sudo sed -i '' '/${self.triggers.flink_host}/d' /etc/hosts 2>/dev/null || true
        echo "DNS cleanup completed"
      fi
    EOF
  }
}