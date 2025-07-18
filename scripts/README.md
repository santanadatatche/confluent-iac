# Scripts de Diagnóstico para Confluent Cloud Private Link

Este diretório contém scripts para diagnosticar e resolver problemas de conectividade com o Confluent Cloud via Private Link, especialmente para gerenciamento de tópicos e Flink.

## Scripts Disponíveis

### 1. `diagnose_privatelink.sh`

Script principal que oferece um menu interativo para diagnóstico completo.

```bash
./scripts/diagnose_privatelink.sh
```

### 2. `check_connectivity.sh`

Verifica a conectividade com o Confluent Cloud nas portas 9092 (Kafka) e 443 (REST API).

```bash
./scripts/check_connectivity.sh <bootstrap_server> [proxy_ip]

# Exemplo:
./scripts/check_connectivity.sh lkc-abc123.us-east-1.aws.private.confluent.cloud
./scripts/check_connectivity.sh lkc-abc123.us-east-1.aws.private.confluent.cloud 10.0.0.1
```

### 3. `check_flink_connectivity.sh`

Verifica a conectividade com o Apache Flink no Confluent Cloud.

```bash
./scripts/check_flink_connectivity.sh <flink_endpoint> [proxy_ip] [bearer_token]

# Exemplo:
./scripts/check_flink_connectivity.sh flink-abc123.us-east-1.aws.confluent.cloud
./scripts/check_flink_connectivity.sh flink-abc123.us-east-1.aws.confluent.cloud 10.0.0.1 eyJhbGciOiJIUzI1NiJ9...
```

### 4. `setup_dns.sh`

Configura entradas DNS locais para Confluent Cloud e Flink.

```bash
sudo ./scripts/setup_dns.sh <proxy_ip> <bootstrap_server> [flink_endpoint]

# Exemplo:
sudo ./scripts/setup_dns.sh 10.0.0.1 lkc-abc123.us-east-1.aws.private.confluent.cloud
sudo ./scripts/setup_dns.sh 10.0.0.1 lkc-abc123.us-east-1.aws.private.confluent.cloud flink-abc123.us-east-1.aws.confluent.cloud
```

## Solução de Problemas Comuns

### 1. Problemas de DNS

Se você estiver enfrentando problemas de DNS:

```bash
# Configure o DNS local
sudo ./scripts/setup_dns.sh <proxy_ip> <bootstrap_server> [flink_endpoint]

# Verifique a resolução DNS
dig +short <bootstrap_server>
```

### 2. Problemas de Conectividade

Se você estiver enfrentando problemas de conectividade:

```bash
# Verifique a conectividade com Kafka
./scripts/check_connectivity.sh <bootstrap_server> [proxy_ip]

# Verifique a conectividade com Flink
./scripts/check_flink_connectivity.sh <flink_endpoint> [proxy_ip]
```

### 3. Problemas com o Proxy NGINX

Se você estiver usando um proxy NGINX:

```bash
# Verifique os logs do NGINX
ssh -i .ssh/terraform_aws_rsa ubuntu@<proxy_ip> 'sudo tail -f /var/log/nginx/stream-access.log'

# Verifique a configuração do NGINX
ssh -i .ssh/terraform_aws_rsa ubuntu@<proxy_ip> 'sudo cat /etc/nginx/nginx.conf'

# Verifique o status do NGINX
ssh -i .ssh/terraform_aws_rsa ubuntu@<proxy_ip> 'sudo systemctl status nginx'
```

## Baseado no Insight

Estes scripts foram inspirados pelo repositório [confluent-networking-experiments](https://github.com/takabayashi/confluent-networking-experiments), que utiliza o OpenSSL para verificar a conectividade com o bootstrap server do Confluent Cloud.

## Referências

- [Documentação oficial do Confluent Cloud sobre Private Link](https://docs.confluent.io/cloud/current/networking/ccloud-console-access.html)
- [Documentação sobre Flink Private Networking](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/private-networking.html)