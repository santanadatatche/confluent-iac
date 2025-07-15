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

# Adicionar entrada no /etc/hosts para o cluster (apenas informativo no GitHub Actions)
HOSTS_ENTRY="127.0.0.1 ${CLUSTER_ID}.${REGION}.aws.confluent.cloud"
echo "Entrada DNS que seria adicionada: $HOSTS_ENTRY"

# No GitHub Actions, não podemos modificar /etc/hosts, então apenas exibimos a informação
echo "Executando em ambiente CI/CD - pulando modificação de arquivos do sistema"

# Exibir informações de DNS para diagnóstico
echo "Informações de DNS:"
cat /etc/resolv.conf || echo "Não foi possível ler /etc/resolv.conf"

echo "Configuração DNS concluída (modo informativo)"