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

# Verificar se o state existe localmente
if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
  echo -e "${GREEN}Arquivo de state encontrado localmente.${NC}"
else
  echo -e "${YELLOW}Arquivo de state não encontrado localmente.${NC}"
  
  # Verificar se as credenciais AWS estão configuradas
  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "${YELLOW}Credenciais AWS não encontradas no ambiente. Solicitando credenciais...${NC}"
    
    read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
    read -sp "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
    echo
    
    export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
  fi
  
  echo -e "${YELLOW}Tentando recuperar state do S3...${NC}"
  terraform init || {
    echo -e "${RED}Não foi possível recuperar o state do S3. Continuando sem state...${NC}"
  }
fi

# Obter as entradas DNS diretamente da AWS CLI
echo -e "${YELLOW}Obtendo configuração DNS diretamente da AWS CLI...${NC}"

# Executar o script para obter os IPs diretamente da AWS CLI
"$PROJECT_DIR/scripts/get_vpc_endpoint_ips.sh"

# Verificar se o arquivo dns_entries.txt foi criado
if [ -f "$PROJECT_DIR/dns_entries.txt" ]; then
  DNS_ENTRIES=$(cat "$PROJECT_DIR/dns_entries.txt")
else
  echo -e "${YELLOW}Não foi possível obter as entradas DNS automaticamente.${NC}"
  
  # Perguntar se deseja adicionar manualmente
  read -p "Deseja adicionar as entradas DNS manualmente? (s/n): " ADD_MANUALLY
  if [[ "$ADD_MANUALLY" =~ ^[Ss]$ ]]; then
    "$PROJECT_DIR/scripts/manual_dns_entries.sh"
    
    # Verificar se o arquivo dns_entries.txt foi criado
    if [ -f "dns_entries.txt" ]; then
      DNS_ENTRIES=$(cat "dns_entries.txt")
      mv "dns_entries.txt" "$PROJECT_DIR/dns_entries.txt"
    else
      echo -e "${RED}Não foi possível obter as entradas DNS. Tentando executar destroy diretamente...${NC}"
      DNS_ENTRIES=""
    fi
  else
    echo -e "${RED}Continuando sem entradas DNS. O destroy pode falhar...${NC}"
    DNS_ENTRIES=""
  fi
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