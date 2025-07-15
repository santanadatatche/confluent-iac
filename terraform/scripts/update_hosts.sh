#!/bin/bash
set -e

# Obter o IP público do proxy e o hostname do cluster
PROXY_IP=$1
CLUSTER_HOSTNAME=$2
FLINK_HOSTNAME=$3

if [ -z "$PROXY_IP" ] || [ -z "$CLUSTER_HOSTNAME" ] || [ -z "$FLINK_HOSTNAME" ]; then
  echo "Uso: $0 <proxy_ip> <cluster_hostname> <flink_hostname>"
  exit 1
fi

# Criar arquivo hosts temporário
echo "Criando arquivo hosts temporário..."
cat > /tmp/confluent_hosts << EOF
# Confluent Cloud hosts
$PROXY_IP $CLUSTER_HOSTNAME
$PROXY_IP $FLINK_HOSTNAME
EOF

# Adicionar ao /etc/hosts
echo "Adicionando entradas ao /etc/hosts..."

# Verificar se estamos no GitHub Actions
if [ -n "$GITHUB_ACTIONS" ]; then
  echo "Detectado ambiente GitHub Actions"
  
  # No GitHub Actions, precisamos usar sudo
  sudo bash -c "cat /tmp/confluent_hosts >> /etc/hosts"
  
  # Verificar se a adição foi bem-sucedida
  if grep -q "$CLUSTER_HOSTNAME" /etc/hosts; then
    echo "Entradas adicionadas com sucesso ao /etc/hosts"
  else
    echo "Falha ao adicionar entradas ao /etc/hosts"
    exit 1
  fi
else
  # Em ambiente local
  if [ -w "/etc/hosts" ]; then
    # Se temos permissão de escrita direta
    cat /tmp/confluent_hosts >> /etc/hosts
  else
    # Se precisamos de sudo
    sudo bash -c "cat /tmp/confluent_hosts >> /etc/hosts"
  fi
  
  echo "Entradas adicionadas ao /etc/hosts"
fi

# Exibir o conteúdo atual do /etc/hosts
echo "Conteúdo atual do /etc/hosts:"
cat /etc/hosts

# Testar resolução de DNS
echo "Testando resolução de DNS para $CLUSTER_HOSTNAME:"
getent hosts $CLUSTER_HOSTNAME || echo "Falha na resolução de DNS para $CLUSTER_HOSTNAME"

echo "Testando resolução de DNS para $FLINK_HOSTNAME:"
getent hosts $FLINK_HOSTNAME || echo "Falha na resolução de DNS para $FLINK_HOSTNAME"

echo "Configuração de hosts concluída!"