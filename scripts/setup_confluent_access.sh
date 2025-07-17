#!/bin/bash

# Script para configurar acesso ao Confluent Cloud via CLI com Private Link
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
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Configurando acesso ao Confluent Cloud via CLI com Private Link ===${NC}"

# Navegar para o diretório do ambiente
cd "$ENV_DIR"

# Verificar se o Terraform está inicializado
if [ ! -d ".terraform" ]; then
  echo -e "${YELLOW}Inicializando Terraform...${NC}"
  terraform init
fi

# Obter informações do cluster
echo -e "${YELLOW}Obtendo informações do cluster Kafka...${NC}"
CLUSTER_ID=$(terraform output -raw kafka_cluster_id 2>/dev/null || echo "")
BOOTSTRAP_ENDPOINT=$(terraform output -raw kafka_bootstrap_endpoint 2>/dev/null || echo "")
REST_ENDPOINT=$(terraform output -raw kafka_rest_endpoint 2>/dev/null || echo "")

if [ -z "$CLUSTER_ID" ] || [ -z "$BOOTSTRAP_ENDPOINT" ] || [ -z "$REST_ENDPOINT" ]; then
  echo -e "${RED}Não foi possível obter informações do cluster. Verifique se o Terraform foi aplicado corretamente.${NC}"
  exit 1
fi

# Obter entradas DNS
echo -e "${YELLOW}Obtendo configuração DNS necessária...${NC}"
DNS_ENTRIES=$(terraform output -raw hosts_command_for_destroy 2>/dev/null | grep -v "echo\|sudo\|cat\|EOF\|#" | grep -v "^$" || echo "")

if [ -z "$DNS_ENTRIES" ]; then
  echo -e "${RED}Não foi possível obter as entradas DNS. Verifique se o módulo privatelink foi atualizado.${NC}"
  exit 1
fi

# Adicionar entradas temporárias ao /etc/hosts
echo -e "${YELLOW}Adicionando entradas DNS temporárias ao /etc/hosts...${NC}"
echo "$DNS_ENTRIES"

# Verificar se as entradas já existem
if grep -q "${DNS_ENTRIES}" /etc/hosts; then
  echo -e "${GREEN}Entradas DNS já existem no /etc/hosts.${NC}"
else
  # Solicitar senha sudo para adicionar as entradas
  echo -e "${YELLOW}Solicitando permissão sudo para modificar /etc/hosts...${NC}"
  echo "$DNS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null
  echo -e "${GREEN}Entradas DNS adicionadas com sucesso!${NC}"
fi

# Verificar se o Confluent CLI está instalado
if ! command -v confluent &> /dev/null; then
  echo -e "${YELLOW}Confluent CLI não encontrado. Instalando...${NC}"
  curl -sL --http1.1 https://cnfl.io/cli | sh -s -- -b /usr/local/bin
  echo -e "${GREEN}Confluent CLI instalado com sucesso!${NC}"
fi

# Configurar variáveis de ambiente
echo -e "${YELLOW}Configurando variáveis de ambiente...${NC}"
export CONFLUENT_CLOUD_API_KEY="${CONFLUENT_CLOUD_API_KEY:-}"
export CONFLUENT_CLOUD_API_SECRET="${CONFLUENT_CLOUD_API_SECRET:-}"

if [ -z "$CONFLUENT_CLOUD_API_KEY" ] || [ -z "$CONFLUENT_CLOUD_API_SECRET" ]; then
  echo -e "${YELLOW}Credenciais Confluent Cloud não encontradas no ambiente.${NC}"
  echo -e "${YELLOW}Por favor, forneça suas credenciais:${NC}"
  
  read -p "Confluent Cloud API Key: " CONFLUENT_CLOUD_API_KEY
  read -sp "Confluent Cloud API Secret: " CONFLUENT_CLOUD_API_SECRET
  echo
  
  export CONFLUENT_CLOUD_API_KEY="$CONFLUENT_CLOUD_API_KEY"
  export CONFLUENT_CLOUD_API_SECRET="$CONFLUENT_CLOUD_API_SECRET"
fi

# Login no Confluent Cloud
echo -e "${YELLOW}Fazendo login no Confluent Cloud...${NC}"
confluent login --save

# Exibir informações úteis
echo -e "${GREEN}Configuração concluída com sucesso!${NC}"
echo -e "${BLUE}=== Informações do Cluster ===${NC}"
echo -e "${YELLOW}Cluster ID:${NC} $CLUSTER_ID"
echo -e "${YELLOW}Bootstrap Endpoint:${NC} $BOOTSTRAP_ENDPOINT"
echo -e "${YELLOW}REST Endpoint:${NC} $REST_ENDPOINT"

echo -e "${BLUE}=== Comandos Úteis ===${NC}"
echo -e "${YELLOW}Listar tópicos:${NC}"
echo -e "confluent kafka topic list --cluster $CLUSTER_ID"
echo
echo -e "${YELLOW}Criar tópico:${NC}"
echo -e "confluent kafka topic create <nome-do-topico> --cluster $CLUSTER_ID --partitions 3"
echo
echo -e "${YELLOW}Excluir tópico:${NC}"
echo -e "confluent kafka topic delete <nome-do-topico> --cluster $CLUSTER_ID"
echo
echo -e "${YELLOW}Listar conectores:${NC}"
echo -e "confluent connect list --cluster $CLUSTER_ID"
echo
echo -e "${YELLOW}Acessar Flink:${NC}"
echo -e "curl -H \"Authorization: Bearer \$CONFLUENT_TOKEN\" https://flink.$(echo $REST_ENDPOINT | cut -d'.' -f2-)"
echo
echo -e "${BLUE}=== Limpeza ===${NC}"
echo -e "Para remover as entradas DNS temporárias, execute:"
echo -e "sudo grep -v -F \"$DNS_ENTRIES\" /etc/hosts > /tmp/hosts.tmp && sudo mv /tmp/hosts.tmp /etc/hosts"