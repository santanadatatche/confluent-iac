#!/bin/bash

# Script para executar terraform apply com configuração DNS temporária
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

echo -e "${YELLOW}Iniciando processo de apply seguro para Confluent Cloud com Private Link...${NC}"

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

# Verificar se o Terraform está inicializado
if [ ! -d ".terraform" ]; then
  echo -e "${YELLOW}Inicializando Terraform...${NC}"
  terraform init
fi

# Executar terraform apply
echo -e "${YELLOW}Executando terraform apply...${NC}"
terraform apply -auto-approve

# Após o apply, configurar DNS para acesso
echo -e "${YELLOW}Configurando DNS para acesso ao Confluent Cloud...${NC}"

# Obter o comando de hosts
HOSTS_COMMAND=$(terraform output -raw hosts_command 2>/dev/null || echo "")

if [ -z "$HOSTS_COMMAND" ]; then
  echo -e "${RED}Não foi possível obter o comando de hosts. Tentando obter as entradas DNS manualmente...${NC}"
  "$PROJECT_DIR/scripts/get_vpc_endpoint_ips.sh"
  
  # Verificar se o arquivo dns_entries.txt foi criado
  if [ -f "$PROJECT_DIR/dns_entries.txt" ]; then
    DNS_ENTRIES=$(cat "$PROJECT_DIR/dns_entries.txt")
    
    echo -e "${YELLOW}Adicionando entradas DNS ao /etc/hosts...${NC}"
    echo "$DNS_ENTRIES"
    
    # Solicitar senha sudo para adicionar as entradas
    echo -e "${YELLOW}Solicitando permissão sudo para modificar /etc/hosts...${NC}"
    echo "$DNS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null
    
    echo -e "${GREEN}Entradas DNS adicionadas com sucesso!${NC}"
    
    # Limpar arquivo temporário
    rm -f "$PROJECT_DIR/dns_entries.txt"
  else
    echo -e "${RED}Não foi possível obter as entradas DNS. Você precisará configurar o DNS manualmente.${NC}"
  fi
else
  echo -e "${YELLOW}Executando comando de hosts...${NC}"
  eval "$HOSTS_COMMAND"
  echo -e "${GREEN}DNS configurado com sucesso!${NC}"
fi

echo -e "${GREEN}Processo de apply concluído!${NC}"
echo -e "${YELLOW}Para acessar o Confluent Cloud via CLI, execute:${NC}"
echo -e "./scripts/setup_confluent_access.sh"