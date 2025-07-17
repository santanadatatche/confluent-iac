#!/bin/bash

# Script para adicionar manualmente entradas DNS para Confluent Cloud Private Link
# Autor: Amazon Q
# Data: 2024

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Adicionando entradas DNS manualmente para Confluent Cloud Private Link...${NC}"

# Solicitar informações necessárias
read -p "IP do VPC Endpoint: " ENDPOINT_IP
read -p "Domínio DNS do Private Link (ex: pr123a.us-east-2.aws.confluent.cloud): " DNS_DOMAIN
read -p "ID do Cluster Kafka (ex: lkc-xxxxx): " CLUSTER_ID

# Extrair o network ID do domínio DNS
NETWORK_ID=$(echo "$DNS_DOMAIN" | cut -d'.' -f1)

# Criar entradas DNS
DNS_ENTRIES="$ENDPOINT_IP *.${DNS_DOMAIN}
$ENDPOINT_IP ${CLUSTER_ID}.${DNS_DOMAIN}
$ENDPOINT_IP ${NETWORK_ID}.${DNS_DOMAIN}
$ENDPOINT_IP flink.${DNS_DOMAIN}"

# Exibir entradas DNS
echo -e "${GREEN}Entradas DNS:${NC}"
echo "$DNS_ENTRIES"

# Perguntar se deseja adicionar ao /etc/hosts
read -p "Deseja adicionar estas entradas ao /etc/hosts? (s/n): " ADD_TO_HOSTS
if [[ "$ADD_TO_HOSTS" =~ ^[Ss]$ ]]; then
  echo -e "${YELLOW}Adicionando entradas ao /etc/hosts...${NC}"
  echo "$DNS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null
  echo -e "${GREEN}Entradas adicionadas com sucesso!${NC}"
fi

# Salvar em um arquivo
echo "$DNS_ENTRIES" > dns_entries.txt
echo -e "${GREEN}Entradas DNS salvas em dns_entries.txt${NC}"

echo -e "${YELLOW}Para remover estas entradas posteriormente, execute:${NC}"
echo -e "sudo grep -v -F \"$ENDPOINT_IP\" /etc/hosts > /tmp/hosts.tmp && sudo mv /tmp/hosts.tmp /etc/hosts"