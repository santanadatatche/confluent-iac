terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.32.0"
    }
  }
}

data "aws_internet_gateway" "existing" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.existing.id
  }
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.proxy_subnet_cidr
  availability_zone       = var.aws_default_zones[0].zone
  map_public_ip_on_launch = true
}

data "aws_vpc" "proxy_vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "public" {
  name_prefix = "confluent-proxy-sg-"
  vpc_id = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.my_public_ip.result.ip}/32"]
    description = "SSH access from public IP"
  }

  # HTTPS access from public IP
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${data.external.my_public_ip.result.ip}/32"]
    description = "HTTPS access from public IP"
  }

  # Kafka access from public IP
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["${data.external.my_public_ip.result.ip}/32"]
    description = "Kafka access from public IP"
  }

  # HTTPS access from VPC (for internal routing)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.proxy_vpc.cidr_block]
    description = "HTTPS access from VPC"
  }

  # Kafka access from VPC (for internal routing)
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.proxy_vpc.cidr_block]
    description = "Kafka access from VPC"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "confluent-proxy-security-group"
  }
}

#### SSH Key Generation
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "./.ssh/terraform_aws_rsa"
}

resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "./.ssh/terraform_aws_rsa.pub"
}

resource "aws_key_pair" "deployer" {
  key_name   = "ubuntu_proxy_ssh_key"
  public_key = tls_private_key.ssh_key.public_key_openssh
  tags = {
    Name = "confluent-proxy-ssh-key"
  }
  lifecycle {
    ignore_changes = [public_key]
  }
}

## Proxy Configuration
resource "aws_instance" "proxy" {
  ami                         = var.aws_default_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.public.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  depends_on = [
    aws_security_group.public,
    aws_key_pair.deployer,
    aws_route_table_association.public_rt_association
  ]
  
  user_data = base64encode(<<-EOF
#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user-data script"

# Update system
apt-get update -y
apt-get install -y nginx netcat-openbsd

# Create NGINX configuration
cat > /etc/nginx/nginx.conf << 'EOL'
load_module /usr/lib/nginx/modules/ngx_stream_module.so;
events {}
stream {
    map $ssl_preread_server_name $targetBackend {
        default $ssl_preread_server_name;
    }

    resolver 169.254.169.253 valid=10s;
    resolver_timeout 5s;

    server {
        listen 9092;
        proxy_connect_timeout 5s;
        proxy_timeout 7200s;
        proxy_pass $targetBackend:9092;
        ssl_preread on;
    }

    server {
        listen 443;
        proxy_connect_timeout 5s;
        proxy_timeout 7200s;
        proxy_pass $targetBackend:443;
        ssl_preread on;
    }

    log_format stream_routing '[$time_local] remote address $remote_addr with SNI name "$ssl_preread_server_name" proxied to "$upstream_addr" $protocol $status $bytes_sent $bytes_received $session_time';
    access_log /var/log/nginx/stream-access.log stream_routing;
    error_log /var/log/nginx/stream-error.log;
}
EOL

# Test and start NGINX
nginx -t
systemctl enable nginx
systemctl restart nginx
systemctl status nginx

echo "User-data script completed successfully"
EOF
  )

  # Wait for instance to be ready
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo systemctl is-active nginx",
      "sudo netstat -tlnp | grep nginx || sudo ss -tlnp | grep nginx"
    ]
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = self.public_ip
      timeout     = "5m"
    }
  }


  
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "confluent-proxy"
  }
}

# Resource to ensure proxy is fully ready
resource "null_resource" "proxy_ready" {
  depends_on = [aws_instance.proxy]
  
  provisioner "local-exec" {
    command = <<-EOF
      echo "Waiting for proxy to be ready..."
      for i in {1..30}; do
        if nc -z ${aws_instance.proxy.public_ip} 443 && nc -z ${aws_instance.proxy.public_ip} 9092; then
          echo "Proxy is ready!"
          exit 0
        fi
        echo "Attempt $i: Proxy not ready yet, waiting 10 seconds..."
        sleep 10
      done
      echo "Proxy failed to become ready after 5 minutes"
      exit 1
    EOF
  }

  triggers = {
    proxy_id = aws_instance.proxy.id
  }
}