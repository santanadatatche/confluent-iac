#!/bin/bash
# Script para verificar a conectividade com o Apache Flink no Confluent Cloud via Private Link

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Função para verificar se um comando existe
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Verificar dependências
if ! command_exists curl; then
  echo -e "${RED}Erro: curl não está instalado. Por favor, instale-o primeiro.${NC}"
  exit 1
fi

if ! command_exists jq; then
  echo -e "${YELLOW}Aviso: jq não está instalado. A formatação JSON não estará disponível.${NC}"
fi

# Verificar se o endpoint Flink foi fornecido
if [ -z "$1" ]; then
  echo -e "${YELLOW}Uso: $0 <flink_endpoint> [proxy_ip] [bearer_token]${NC}"
  echo -e "Exemplo: $0 flink-abc123.us-east-1.aws.confluent.cloud"
  echo -e "Exemplo com proxy: $0 flink-abc123.us-east-1.aws.confluent.cloud 10.0.0.1 eyJhbGciOiJIUzI1NiJ9..."
  
  # Tentar obter o endpoint Flink do Terraform
  echo -e "${YELLOW}Tentando obter endpoint Flink do Terraform...${NC}"
  FLINK_ENDPOINT=$(terraform output -raw flink_private_endpoint 2>/dev/null)
  
  if [ -z "$FLINK_ENDPOINT" ]; then
    echo -e "${RED}Não foi possível obter o endpoint Flink automaticamente.${NC}"
    exit 1
  else
    echo -e "${GREEN}Endpoint Flink encontrado: $FLINK_ENDPOINT${NC}"
  fi
else
  FLINK_ENDPOINT=$1
fi

# Verificar se um proxy foi especificado
PROXY_IP=$2
if [ -n "$PROXY_IP" ]; then
  echo -e "${YELLOW}Usando proxy $PROXY_IP para conexão${NC}"
  PROXY_HOST=$PROXY_IP
else
  PROXY_HOST=$FLINK_ENDPOINT
fi

# Verificar se um token foi fornecido
BEARER_TOKEN=$3
if [ -z "$BEARER_TOKEN" ]; then
  echo -e "${YELLOW}Nenhum token de autenticação fornecido. Algumas verificações podem falhar.${NC}"
  AUTH_HEADER=""
else
  AUTH_HEADER="-H \"Authorization: Bearer $BEARER_TOKEN\""
fi

echo -e "${YELLOW}Verificando conectividade com Flink em $FLINK_ENDPOINT...${NC}"

# Verificar conectividade na porta 443 (Flink API)
echo -e "\n${YELLOW}Testando conectividade na porta 443 (Flink API)...${NC}"
if [ -n "$PROXY_IP" ]; then
  FLINK_RESULT=$(openssl s_client -connect ${PROXY_IP}:443 -servername $FLINK_ENDPOINT -verify_hostname $FLINK_ENDPOINT </dev/null 2>&1)
else
  FLINK_RESULT=$(openssl s_client -connect ${FLINK_ENDPOINT}:443 -servername $FLINK_ENDPOINT -verify_hostname $FLINK_ENDPOINT </dev/null 2>&1)
fi
FLINK_STATUS=$?

if echo "$FLINK_RESULT" | grep -q "BEGIN CERTIFICATE"; then
  echo -e "${GREEN}✓ Conexão estabelecida com sucesso na porta 443${NC}"
  echo -e "${YELLOW}Detalhes do certificado:${NC}"
  echo "$FLINK_RESULT" | grep -E 'Verify return code|subject|issuer' | head -3
else
  echo -e "${RED}✗ Falha na conexão com a porta 443${NC}"
  echo -e "${YELLOW}Detalhes do erro:${NC}"
  echo "$FLINK_RESULT" | grep -E 'error|fail|refused' | head -3
fi

# Verificar DNS
echo -e "\n${YELLOW}Verificando resolução DNS para $FLINK_ENDPOINT...${NC}"
DNS_RESULT=$(dig +short $FLINK_ENDPOINT 2>&1)
if [ -n "$DNS_RESULT" ]; then
  echo -e "${GREEN}✓ DNS resolvido com sucesso: $DNS_RESULT${NC}"
else
  echo -e "${RED}✗ Falha na resolução DNS${NC}"
  echo -e "${YELLOW}Tente adicionar uma entrada no arquivo /etc/hosts ou configurar o DNS privado${NC}"
fi

# Testar API do Flink se o token foi fornecido
if [ -n "$BEARER_TOKEN" ]; then
  echo -e "\n${YELLOW}Testando API do Flink...${NC}"
  
  # Construir comando curl com ou sem proxy
  if [ -n "$PROXY_IP" ]; then
    CURL_CMD="curl -s -H \"Host: $FLINK_ENDPOINT\" -H \"Authorization: Bearer $BEARER_TOKEN\" https://$PROXY_IP/v1/sql/statements"
  else
    CURL_CMD="curl -s -H \"Authorization: Bearer $BEARER_TOKEN\" https://$FLINK_ENDPOINT/v1/sql/statements"
  fi
  
  # Executar comando
  API_RESULT=$(eval $CURL_CMD)
  API_STATUS=$?
  
  if [ $API_STATUS -eq 0 ] && ! echo "$API_RESULT" | grep -q "error"; then
    echo -e "${GREEN}✓ API do Flink respondeu com sucesso${NC}"
    if command_exists jq; then
      echo "$API_RESULT" | jq '.'
    else
      echo "$API_RESULT" | head -20
    fi
  else
    echo -e "${RED}✗ Falha ao acessar a API do Flink${NC}"
    echo -e "${YELLOW}Resposta:${NC}"
    echo "$API_RESULT"
  fi
fi

# Verificar se o proxy NGINX está configurado corretamente (se aplicável)
if [ -n "$PROXY_IP" ]; then
  echo -e "\n${YELLOW}Verificando configuração do proxy NGINX para Flink...${NC}"
  echo -e "${YELLOW}Comando para verificar logs do NGINX:${NC}"
  echo "ssh -i .ssh/terraform_aws_rsa ubuntu@$PROXY_IP 'sudo tail -f /var/log/nginx/stream-access.log'"
  
  echo -e "\n${YELLOW}Comando para testar conectividade direta:${NC}"
  echo "nc -zv $PROXY_IP 443"
fi

# Resumo
echo -e "\n${YELLOW}=== Resumo da Conectividade do Flink ===${NC}"
if [ $FLINK_STATUS -eq 0 ]; then
  echo -e "${GREEN}✓ Conectividade com Flink está funcionando corretamente${NC}"
  echo -e "${GREEN}✓ Porta 443 (API) está acessível${NC}"
  
  # Sugestão para configurar cliente Flink
  echo -e "\n${YELLOW}Comandos úteis para Flink:${NC}"
  echo "# Verificar status do Flink"
  if [ -n "$BEARER_TOKEN" ]; then
    if [ -n "$PROXY_IP" ]; then
      echo "curl -H \"Host: $FLINK_ENDPOINT\" -H \"Authorization: Bearer $BEARER_TOKEN\" https://$PROXY_IP/v1/sql/statements"
    else
      echo "curl -H \"Authorization: Bearer $BEARER_TOKEN\" https://$FLINK_ENDPOINT/v1/sql/statements"
    fi
  else
    echo "curl -H \"Authorization: Bearer <seu_token>\" https://$FLINK_ENDPOINT/v1/sql/statements"
  fi
else
  echo -e "${RED}✗ Problemas de conectividade com Flink detectados${NC}"
  
  echo -e "\n${YELLOW}Possíveis soluções:${NC}"
  echo "1. Verifique se o Private Link está configurado corretamente"
  echo "2. Verifique se as entradas DNS estão configuradas"
  echo "3. Verifique se os security groups permitem tráfego na porta 443"
  echo "4. Se estiver usando proxy, verifique se o NGINX está configurado corretamente para SNI"
  echo "5. Execute o comando para configurar DNS: terraform output -raw hosts_command"
  echo "6. Verifique se o Flink está habilitado no seu ambiente Confluent Cloud"
fi

exit 0