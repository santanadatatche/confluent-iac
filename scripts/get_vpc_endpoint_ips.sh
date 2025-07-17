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
CLUSTER_ID=$(terraform output -raw kafka_cluster_id 2>/dev/null || echo "")

# Se não conseguir obter o domínio DNS, tentar extrair do bootstrap endpoint
if [ -z "$DNS_DOMAIN" ]; then
  BOOTSTRAP_ENDPOINT=$(terraform output -raw kafka_bootstrap_endpoint 2>/dev/null || echo "")
  if [ ! -z "$BOOTSTRAP_ENDPOINT" ]; then
    # Extrair o domínio do bootstrap endpoint (formato: lkc-xxxxx.region.cloud.confluent.cloud:9092)
    DNS_DOMAIN=$(echo "$BOOTSTRAP_ENDPOINT" | cut -d':' -f1 | cut -d'.' -f2-)
    echo -e "${YELLOW}Domínio DNS extraído do bootstrap endpoint: $DNS_DOMAIN${NC}"
  fi
fi

# Extrair o network ID do domínio DNS ou do cluster ID
if [ ! -z "$DNS_DOMAIN" ]; then
  NETWORK_ID=$(echo "$DNS_DOMAIN" | cut -d'.' -f1)
else
  # Se não tiver o domínio DNS, tentar usar o cluster ID como network ID
  NETWORK_ID=$CLUSTER_ID
fi

# Se ainda não tiver as informações necessárias, solicitar entrada manual
if [ -z "$VPC_ENDPOINT_ID" ] || [ -z "$DNS_DOMAIN" ]; then
  echo -e "${RED}Não foi possível obter o ID do VPC Endpoint ou o domínio DNS.${NC}"
  
  # Solicitar entrada manual
  echo -e "${YELLOW}Por favor, forneça as informações manualmente:${NC}"
  read -p "ID do VPC Endpoint (ex: vpce-0123456789abcdef0): " VPC_ENDPOINT_ID
  read -p "Domínio DNS do Private Link (ex: pr123a.us-east-2.aws.confluent.cloud): " DNS_DOMAIN
  read -p "ID do Cluster Kafka (ex: lkc-xxxxx): " CLUSTER_ID
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
  # Entrada wildcard para todos os serviços
  DNS_ENTRIES+="$IP *.${DNS_DOMAIN}\n"
  
  # Entrada específica para o cluster Kafka
  if [ ! -z "$CLUSTER_ID" ]; then
    DNS_ENTRIES+="$IP ${CLUSTER_ID}.${DNS_DOMAIN}\n"
  fi
  
  # Entrada para o domínio principal (network ID)
  if [ ! -z "$NETWORK_ID" ] && [ "$NETWORK_ID" != "$CLUSTER_ID" ]; then
    DNS_ENTRIES+="$IP ${NETWORK_ID}.${DNS_DOMAIN}\n"
  fi
  
  # Entrada para Flink
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