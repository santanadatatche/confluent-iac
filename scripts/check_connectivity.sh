#!/bin/bash
# Script para verificar a conectividade com o Confluent Cloud via Private Link
# Baseado no insight do repositório: https://github.com/takabayashi/confluent-networking-experiments

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
if ! command_exists openssl; then
  echo -e "${RED}Erro: OpenSSL não está instalado. Por favor, instale-o primeiro.${NC}"
  exit 1
fi

# Verificar se o bootstrap server foi fornecido
if [ -z "$1" ]; then
  echo -e "${YELLOW}Uso: $0 <bootstrap_server> [proxy_ip]${NC}"
  echo -e "Exemplo: $0 lkc-abc123.us-east-1.aws.private.confluent.cloud"
  echo -e "Exemplo com proxy: $0 lkc-abc123.us-east-1.aws.private.confluent.cloud 10.0.0.1"
  
  # Tentar obter o bootstrap server do Terraform
  echo -e "${YELLOW}Tentando obter bootstrap server do Terraform...${NC}"
  BOOTSTRAP=$(terraform output -raw kafka_bootstrap_endpoint 2>/dev/null | cut -d':' -f1)
  
  if [ -z "$BOOTSTRAP" ]; then
    echo -e "${RED}Não foi possível obter o bootstrap server automaticamente.${NC}"
    exit 1
  else
    echo -e "${GREEN}Bootstrap server encontrado: $BOOTSTRAP${NC}"
    BOOTSTRAP_SERVER=$BOOTSTRAP
  fi
else
  BOOTSTRAP_SERVER=$1
fi

# Verificar se um proxy foi especificado
PROXY_IP=$2
if [ -n "$PROXY_IP" ]; then
  echo -e "${YELLOW}Usando proxy $PROXY_IP para conexão${NC}"
  PROXY_OPTION="-connect ${PROXY_IP}:9092"
else
  PROXY_OPTION="-connect ${BOOTSTRAP_SERVER}:9092"
fi

echo -e "${YELLOW}Verificando conectividade com $BOOTSTRAP_SERVER...${NC}"

# Verificar conectividade na porta 9092 (Kafka)
echo -e "\n${YELLOW}Testando conectividade na porta 9092 (Kafka)...${NC}"
KAFKA_RESULT=$(openssl s_client $PROXY_OPTION -servername $BOOTSTRAP_SERVER -verify_hostname $BOOTSTRAP_SERVER </dev/null 2>&1)
KAFKA_STATUS=$?

if echo "$KAFKA_RESULT" | grep -q "BEGIN CERTIFICATE"; then
  echo -e "${GREEN}✓ Conexão estabelecida com sucesso na porta 9092${NC}"
  echo -e "${YELLOW}Detalhes do certificado:${NC}"
  echo "$KAFKA_RESULT" | grep -E 'Verify return code|subject|issuer' | head -3
else
  echo -e "${RED}✗ Falha na conexão com a porta 9092${NC}"
  echo -e "${YELLOW}Detalhes do erro:${NC}"
  echo "$KAFKA_RESULT" | grep -E 'error|fail|refused' | head -3
fi

# Verificar conectividade na porta 443 (REST API)
echo -e "\n${YELLOW}Testando conectividade na porta 443 (REST API)...${NC}"
if [ -n "$PROXY_IP" ]; then
  REST_RESULT=$(openssl s_client -connect ${PROXY_IP}:443 -servername $BOOTSTRAP_SERVER -verify_hostname $BOOTSTRAP_SERVER </dev/null 2>&1)
else
  REST_RESULT=$(openssl s_client -connect ${BOOTSTRAP_SERVER}:443 -servername $BOOTSTRAP_SERVER -verify_hostname $BOOTSTRAP_SERVER </dev/null 2>&1)
fi
REST_STATUS=$?

if echo "$REST_RESULT" | grep -q "BEGIN CERTIFICATE"; then
  echo -e "${GREEN}✓ Conexão estabelecida com sucesso na porta 443${NC}"
  echo -e "${YELLOW}Detalhes do certificado:${NC}"
  echo "$REST_RESULT" | grep -E 'Verify return code|subject|issuer' | head -3
else
  echo -e "${RED}✗ Falha na conexão com a porta 443${NC}"
  echo -e "${YELLOW}Detalhes do erro:${NC}"
  echo "$REST_RESULT" | grep -E 'error|fail|refused' | head -3
fi

# Verificar DNS
echo -e "\n${YELLOW}Verificando resolução DNS para $BOOTSTRAP_SERVER...${NC}"
DNS_RESULT=$(dig +short $BOOTSTRAP_SERVER 2>&1)
if [ -n "$DNS_RESULT" ]; then
  echo -e "${GREEN}✓ DNS resolvido com sucesso: $DNS_RESULT${NC}"
else
  echo -e "${RED}✗ Falha na resolução DNS${NC}"
  echo -e "${YELLOW}Tente adicionar uma entrada no arquivo /etc/hosts ou configurar o DNS privado${NC}"
fi

# Verificar se o proxy NGINX está configurado corretamente (se aplicável)
if [ -n "$PROXY_IP" ]; then
  echo -e "\n${YELLOW}Verificando configuração do proxy NGINX...${NC}"
  echo -e "${YELLOW}Comando para verificar logs do NGINX:${NC}"
  echo "ssh -i .ssh/terraform_aws_rsa ubuntu@$PROXY_IP 'sudo tail -f /var/log/nginx/stream-access.log'"
  
  echo -e "\n${YELLOW}Comando para testar conectividade direta:${NC}"
  echo "nc -zv $PROXY_IP 9092"
  echo "nc -zv $PROXY_IP 443"
fi

# Resumo
echo -e "\n${YELLOW}=== Resumo da Conectividade ===${NC}"
if [ $KAFKA_STATUS -eq 0 ] && [ $REST_STATUS -eq 0 ]; then
  echo -e "${GREEN}✓ Conectividade com Confluent Cloud está funcionando corretamente${NC}"
  echo -e "${GREEN}✓ Portas 9092 (Kafka) e 443 (REST) estão acessíveis${NC}"
  
  # Sugestão para configurar cliente Kafka
  echo -e "\n${YELLOW}Configuração para cliente Kafka:${NC}"
  echo "bootstrap.servers=$BOOTSTRAP_SERVER:9092"
  echo "security.protocol=SASL_SSL"
  echo "sasl.mechanism=PLAIN"
  echo "sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"\$CLUSTER_API_KEY\" password=\"\$CLUSTER_API_SECRET\";"
else
  echo -e "${RED}✗ Problemas de conectividade detectados${NC}"
  
  if [ $KAFKA_STATUS -ne 0 ]; then
    echo -e "${RED}✗ Porta 9092 (Kafka) não está acessível${NC}"
  fi
  
  if [ $REST_STATUS -ne 0 ]; then
    echo -e "${RED}✗ Porta 443 (REST) não está acessível${NC}"
  fi
  
  echo -e "\n${YELLOW}Possíveis soluções:${NC}"
  echo "1. Verifique se o Private Link está configurado corretamente"
  echo "2. Verifique se as entradas DNS estão configuradas"
  echo "3. Verifique se os security groups permitem tráfego nas portas 9092 e 443"
  echo "4. Se estiver usando proxy, verifique se o NGINX está configurado corretamente"
  echo "5. Execute o comando para configurar DNS: terraform output -raw hosts_command"
fi

exit 0