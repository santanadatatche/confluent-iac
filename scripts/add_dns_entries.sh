#!/bin/bash

# Script para adicionar entradas DNS manualmente para Confluent Cloud Private Link
# Autor: Amazon Q
# Data: 2024

set -e

# Diretório do projeto
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
ENV_DIR="$PROJECT_DIR/terraform/environments/evoluservices"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Adicionando entradas DNS para Confluent Cloud Private Link...${NC}"

# Navegar para o diretório do ambiente
cd "$ENV_DIR"

# Verificar se o state existe
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
  echo -e "${RED}Arquivo de state não encontrado localmente. Tentando recuperar do S3...${NC}"
  terraform init
fi

# Obter o comando de hosts
echo -e "${YELLOW}Obtendo configuração DNS necessária...${NC}"
HOSTS_ENTRIES=$(terraform output -raw hosts_command_for_destroy 2>/dev/null || echo "")

if [ -z "$HOSTS_ENTRIES" ]; then
  echo -e "${RED}Não foi possível obter as entradas de hosts. O state pode estar corrompido ou inacessível.${NC}"
  
  # Solicitar entrada manual
  echo -e "${YELLOW}Por favor, forneça as informações manualmente:${NC}"
  read -p "IP do VPC Endpoint: " ENDPOINT_IP
  read -p "Domínio DNS do Private Link (ex: pr123a.us-east-2.aws.confluent.cloud): " DNS_DOMAIN
  read -p "ID do Cluster (ex: lkc-abc123): " CLUSTER_ID
  
  # Criar entradas DNS manualmente
  DNS_ENTRIES="$ENDPOINT_IP *.$DNS_DOMAIN
$ENDPOINT_IP $CLUSTER_ID.$DNS_DOMAIN
$ENDPOINT_IP flink.$DNS_DOMAIN"
else
  # Extrair apenas as linhas de IP/hostname do comando
  DNS_ENTRIES=$(echo "$HOSTS_ENTRIES" | grep -v "echo\|sudo\|cat\|EOF\|#" | grep -v "^$")
fi

# Adicionar entradas temporárias ao /etc/hosts
echo -e "${YELLOW}Adicionando entradas DNS ao /etc/hosts:${NC}"
echo "$DNS_ENTRIES"

# Verificar se as entradas já existem
if grep -q "$(echo "$DNS_ENTRIES" | head -n1)" /etc/hosts; then
  echo -e "${YELLOW}Algumas entradas DNS já existem no /etc/hosts. Removendo entradas antigas...${NC}"
  
  # Criar arquivo temporário sem as entradas existentes
  TMP_FILE=$(mktemp)
  grep -v -F "$DNS_ENTRIES" /etc/hosts > "$TMP_FILE"
  
  # Solicitar senha sudo para substituir o arquivo
  echo -e "${YELLOW}Solicitando permissão sudo para modificar /etc/hosts...${NC}"
  sudo mv "$TMP_FILE" /etc/hosts
fi

# Solicitar senha sudo para adicionar as entradas
echo -e "${YELLOW}Solicitando permissão sudo para adicionar entradas ao /etc/hosts...${NC}"
echo "$DNS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null

echo -e "${GREEN}Entradas DNS adicionadas com sucesso!${NC}"
echo -e "${YELLOW}Para remover estas entradas posteriormente, execute:${NC}"
echo -e "sudo grep -v -F \"$(echo "$DNS_ENTRIES" | head -n1 | awk '{print $2}')\" /etc/hosts > /tmp/hosts.tmp && sudo mv /tmp/hosts.tmp /etc/hosts"