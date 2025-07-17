#!/bin/bash

# Script para executar terraform destroy com configuração DNS temporária
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

echo -e "${YELLOW}Iniciando processo de destroy seguro para Confluent Cloud com Private Link...${NC}"

# Navegar para o diretório do ambiente
cd "$ENV_DIR"

# Verificar se o state existe
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
  echo -e "${RED}Arquivo de state não encontrado localmente. Tentando recuperar do S3...${NC}"
  terraform init
fi

# Tentar obter as entradas DNS do output do Terraform
echo -e "${YELLOW}Tentando obter configuração DNS do Terraform...${NC}"
HOSTS_ENTRIES=$(terraform output -raw hosts_command_for_destroy 2>/dev/null || echo "")

if [ -z "$HOSTS_ENTRIES" ] || echo "$HOSTS_ENTRIES" | grep -q "No network interfaces found"; then
  echo -e "${YELLOW}Não foi possível obter as entradas DNS do Terraform. Tentando obter diretamente da AWS CLI...${NC}"
  
  # Executar o script para obter os IPs diretamente da AWS CLI
  "$PROJECT_DIR/scripts/get_vpc_endpoint_ips.sh"
  
  # Verificar se o arquivo dns_entries.txt foi criado
  if [ -f "$PROJECT_DIR/dns_entries.txt" ]; then
    DNS_ENTRIES=$(cat "$PROJECT_DIR/dns_entries.txt")
  else
    echo -e "${RED}Não foi possível obter as entradas DNS. Tentando executar destroy diretamente...${NC}"
    DNS_ENTRIES=""
  fi
else
  # Extrair apenas as linhas de IP/hostname do comando
  DNS_ENTRIES=$(echo "$HOSTS_ENTRIES" | grep -v "echo\|sudo\|cat\|EOF\|#" | grep -v "^$")
fi

# Adicionar entradas temporárias ao /etc/hosts se tivermos DNS_ENTRIES
if [ ! -z "$DNS_ENTRIES" ]; then
  echo -e "${YELLOW}Adicionando entradas DNS temporárias ao /etc/hosts...${NC}"
  echo "$DNS_ENTRIES"
  
  # Solicitar senha sudo para adicionar as entradas
  echo -e "${YELLOW}Solicitando permissão sudo para modificar /etc/hosts...${NC}"
  echo "$DNS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null
  
  echo -e "${GREEN}Entradas DNS adicionadas com sucesso!${NC}"
fi

# Executar terraform destroy
echo -e "${YELLOW}Executando terraform destroy...${NC}"
terraform destroy -auto-approve

# Limpar entradas do /etc/hosts
if [ ! -z "$DNS_ENTRIES" ]; then
  echo -e "${YELLOW}Removendo entradas temporárias do /etc/hosts...${NC}"
  
  # Criar arquivo temporário sem as entradas adicionadas
  sudo grep -v -F "$DNS_ENTRIES" /etc/hosts > /tmp/hosts.tmp
  sudo mv /tmp/hosts.tmp /etc/hosts
  
  echo -e "${GREEN}Entradas DNS removidas com sucesso!${NC}"
fi

# Limpar arquivo temporário
if [ -f "$PROJECT_DIR/dns_entries.txt" ]; then
  rm -f "$PROJECT_DIR/dns_entries.txt"
fi

echo -e "${GREEN}Processo de destroy concluído!${NC}"