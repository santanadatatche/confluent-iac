#!/bin/bash
set -e

# Configurar DNS para Confluent Cloud
echo "Configurando DNS para Confluent Cloud..."

# Obter o cluster ID do output
CLUSTER_ID=$1
REGION=$2

if [ -z "$CLUSTER_ID" ] || [ -z "$REGION" ]; then
  echo "Uso: $0 <cluster_id> <region>"
  exit 1
fi

# Adicionar entrada no /etc/hosts para o cluster
HOSTS_ENTRY="127.0.0.1 ${CLUSTER_ID}.${REGION}.aws.confluent.cloud"
echo "Adicionando entrada no /etc/hosts: $HOSTS_ENTRY"

# Verificar se a entrada já existe
if grep -q "${CLUSTER_ID}.${REGION}.aws.confluent.cloud" /etc/hosts; then
  echo "Entrada já existe no /etc/hosts"
else
  echo "Adicionando entrada ao /etc/hosts"
  echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts
fi

# Configurar o resolvedor DNS para usar o AWS DNS
echo "Configurando resolvedor DNS..."

# Criar arquivo de configuração temporário
cat > /tmp/confluent-dns.conf << EOF
# Configuração DNS para Confluent Cloud
nameserver 169.254.169.253
EOF

# Mover para o diretório de configuração do resolvedor
sudo cp /tmp/confluent-dns.conf /etc/resolver/confluent.cloud

echo "Configuração DNS concluída!"