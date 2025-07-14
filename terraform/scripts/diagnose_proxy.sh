#!/bin/bash

# Script de diagnóstico para proxy Confluent
# Usage: ./diagnose_proxy.sh <proxy_ip> <cluster_hostname>

PROXY_IP=$1
CLUSTER_HOSTNAME=$2

if [ -z "$PROXY_IP" ] || [ -z "$CLUSTER_HOSTNAME" ]; then
    echo "Usage: $0 <proxy_ip> <cluster_hostname>"
    echo "Example: $0 54.123.45.67 pkc-12345.us-east-2.aws.confluent.cloud"
    exit 1
fi

echo "=== Diagnóstico do Proxy Confluent ==="
echo "Proxy IP: $PROXY_IP"
echo "Cluster Hostname: $CLUSTER_HOSTNAME"
echo ""

# 1. Verificar conectividade básica
echo "1. Testando conectividade básica com o proxy..."
if ping -c 3 $PROXY_IP > /dev/null 2>&1; then
    echo "✅ Proxy está acessível via ping"
else
    echo "❌ Proxy não está acessível via ping"
fi

# 2. Verificar portas do proxy
echo ""
echo "2. Testando portas do proxy..."
for port in 22 443 9092; do
    if nc -z -w5 $PROXY_IP $port 2>/dev/null; then
        echo "✅ Porta $port está aberta no proxy"
    else
        echo "❌ Porta $port não está acessível no proxy"
    fi
done

# 3. Verificar resolução DNS do cluster
echo ""
echo "3. Testando resolução DNS do cluster..."
if nslookup $CLUSTER_HOSTNAME > /dev/null 2>&1; then
    echo "✅ Cluster hostname resolve via DNS"
    echo "   IP: $(nslookup $CLUSTER_HOSTNAME | grep 'Address:' | tail -1 | awk '{print $2}')"
else
    echo "❌ Cluster hostname não resolve via DNS"
fi

# 4. Verificar entrada no /etc/hosts
echo ""
echo "4. Verificando entrada no /etc/hosts..."
if grep -q "$CLUSTER_HOSTNAME" /etc/hosts; then
    echo "✅ Entrada encontrada no /etc/hosts:"
    grep "$CLUSTER_HOSTNAME" /etc/hosts
else
    echo "❌ Nenhuma entrada encontrada no /etc/hosts para $CLUSTER_HOSTNAME"
fi

# 5. Testar conectividade HTTPS através do proxy
echo ""
echo "5. Testando conectividade HTTPS através do proxy..."
if curl -k -m 10 -s https://$CLUSTER_HOSTNAME > /dev/null 2>&1; then
    echo "✅ Conectividade HTTPS funcionando através do proxy"
else
    echo "❌ Falha na conectividade HTTPS através do proxy"
fi

# 6. Testar conectividade Kafka através do proxy
echo ""
echo "6. Testando conectividade Kafka através do proxy..."
if nc -z -w5 $CLUSTER_HOSTNAME 9092 2>/dev/null; then
    echo "✅ Porta 9092 (Kafka) acessível através do proxy"
else
    echo "❌ Porta 9092 (Kafka) não acessível através do proxy"
fi

echo ""
echo "=== Comandos úteis para debug ==="
echo "# Verificar logs do NGINX no proxy:"
echo "ssh -i .ssh/terraform_aws_rsa ubuntu@$PROXY_IP 'sudo tail -f /var/log/nginx/stream-access.log'"
echo ""
echo "# Verificar configuração do NGINX no proxy:"
echo "ssh -i .ssh/terraform_aws_rsa ubuntu@$PROXY_IP 'sudo cat /etc/nginx/nginx.conf'"
echo ""
echo "# Testar conectividade direta do proxy para o cluster:"
echo "ssh -i .ssh/terraform_aws_rsa ubuntu@$PROXY_IP 'nc -zv $CLUSTER_HOSTNAME 9092'"