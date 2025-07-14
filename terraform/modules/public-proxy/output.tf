output "proxy_public_ip" {
  description = "IP público da instância proxy"
  value       = aws_instance.proxy.public_ip
}

output "proxy_public_dns" {
  description = "DNS público da instância proxy"
  value       = aws_instance.proxy.public_dns
}

output "proxy_private_ip" {
  description = "IP privado da instância proxy"
  value       = aws_instance.proxy.private_ip
}

output "cluster_hostname" {
  description = "Hostname do cluster Kafka"
  value       = local.cluster_hostname
}

output "security_group_id" {
  description = "ID do security group do proxy"
  value       = aws_security_group.public.id
}

output "subnet_id" {
  description = "ID da subnet pública do proxy"
  value       = aws_subnet.public_subnet.id
}

output "ssh_command" {
  description = "Comando SSH para acessar o proxy"
  value       = "ssh -i .ssh/terraform_aws_rsa ubuntu@${aws_instance.proxy.public_ip}"
}

output "diagnosis_command" {
  description = "Comando para executar diagnóstico do proxy"
  value       = "bash ../../scripts/diagnose_proxy.sh ${aws_instance.proxy.public_ip} ${local.cluster_hostname}"
}

output "proxy_ready" {
  description = "Indica que o proxy está pronto para uso"
  value       = null_resource.proxy_ready.id
}

output "hosts_command" {
  description = "Comando para configurar /etc/hosts manualmente"
  value       = "sudo bash -c 'echo \"${aws_instance.proxy.public_ip} ${local.cluster_hostname}\" >> /etc/hosts'"
}