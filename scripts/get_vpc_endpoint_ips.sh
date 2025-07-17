#!/bin/bash

# Script para obter os IPs do VPC Endpoint diretamente da AWS CLI
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

echo -e "${YELLOW}Obtendo IPs do VPC Endpoint para Confluent Cloud Private Link...${NC}"

# Navegar para o diretório do ambiente
cd "$ENV_DIR"

# Verificar se o state existe
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
  echo -e "${RED}Arquivo de state não encontrado localmente. Tentando recuperar do S3...${NC}"
  terraform init
fi

# Obter o ID do VPC Endpoint
echo -e "${YELLOW}Obtendo ID do VPC Endpoint...${NC}"
VPC_ENDPOINT_ID=$(terraform output -raw vpc_endpoint_id 2>/dev/null || echo "")
DNS_DOMAIN=$(terraform output -raw platt_dns_domain 2>/dev/null || echo "")
NETWORK_ID=$(echo "$DNS_DOMAIN" | cut -d'.' -f1)

if [ -z "$VPC_ENDPOINT_ID" ] || [ -z "$DNS_DOMAIN" ]; then
  echo -e "${RED}Não foi possível obter o ID do VPC Endpoint ou o domínio DNS.${NC}"
  
  # Solicitar entrada manual
  echo -e "${YELLOW}Por favor, forneça as informações manualmente:${NC}"
  read -p "ID do VPC Endpoint (ex: vpce-0123456789abcdef0): " VPC_ENDPOINT_ID
  read -p "Domínio DNS do Private Link (ex: pr123a.us-east-2.aws.confluent.cloud): " DNS_DOMAIN
  NETWORK_ID=$(echo "$DNS_DOMAIN" | cut -d'.' -f1)
fi

# Verificar se o AWS CLI está instalado
if ! command -v aws &> /dev/null; then
  echo -e "${RED}AWS CLI não encontrado. Por favor, instale o AWS CLI.${NC}"
  exit 1
fi

# Obter as interfaces de rede do VPC Endpoint
echo -e "${YELLOW}Obtendo interfaces de rede do VPC Endpoint...${NC}"
NETWORK_INTERFACES=$(aws ec2 describe-vpc-endpoints --vpc-endpoint-ids "$VPC_ENDPOINT_ID" --query 'VpcEndpoints[0].NetworkInterfaceIds' --output json)

if [ -z "$NETWORK_INTERFACES" ] || [ "$NETWORK_INTERFACES" == "null" ]; then
  echo -e "${RED}Não foi possível obter as interfaces de rede do VPC Endpoint.${NC}"
  exit 1
fi

# Obter os IPs das interfaces de rede
echo -e "${YELLOW}Obtendo IPs das interfaces de rede...${NC}"
IPS=()
for NI_ID in $(echo "$NETWORK_INTERFACES" | jq -r '.[]'); do
  IP=$(aws ec2 describe-network-interfaces --network-interface-ids "$NI_ID" --query 'NetworkInterfaces[0].PrivateIpAddress' --output text)
  IPS+=("$IP")
done

if [ ${#IPS[@]} -eq 0 ]; then
  echo -e "${RED}Não foi possível obter os IPs das interfaces de rede.${NC}"
  exit 1
fi

# Criar entradas DNS
echo -e "${GREEN}IPs encontrados: ${IPS[*]}${NC}"
echo -e "${YELLOW}Criando entradas DNS...${NC}"

DNS_ENTRIES=""
for IP in "${IPS[@]}"; do
  DNS_ENTRIES+="$IP *.${DNS_DOMAIN}\n"
  DNS_ENTRIES+="$IP ${NETWORK_ID}.${DNS_DOMAIN}\n"
  DNS_ENTRIES+="$IP flink.${DNS_DOMAIN}\n"
done

# Exibir entradas DNS
echo -e "${GREEN}Entradas DNS:${NC}"
echo -e "$DNS_ENTRIES"

# Perguntar se deseja adicionar ao /etc/hosts
read -p "Deseja adicionar estas entradas ao /etc/hosts? (s/n): " ADD_TO_HOSTS
if [[ "$ADD_TO_HOSTS" =~ ^[Ss]$ ]]; then
  echo -e "${YELLOW}Adicionando entradas ao /etc/hosts...${NC}"
  echo -e "$DNS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null
  echo -e "${GREEN}Entradas adicionadas com sucesso!${NC}"
fi

# Salvar em um arquivo
echo -e "$DNS_ENTRIES" > "$PROJECT_DIR/dns_entries.txt"
echo -e "${GREEN}Entradas DNS salvas em $PROJECT_DIR/dns_entries.txt${NC}"

echo -e "${GREEN}Processo concluído!${NC}"