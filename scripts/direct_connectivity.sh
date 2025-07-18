#!/bin/bash
# Script para estabelecer conectividade direta com Confluent Cloud
# Baseado na abordagem do repositório: https://github.com/takabayashi/confluent-networking-experiments

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar dependências
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}OpenSSL não está instalado. Por favor, instale-o primeiro.${NC}"
    exit 1
fi

# Obter bootstrap server
if [ -z "$1" ]; then
    # Tentar obter do Terraform
    BOOTSTRAP=$(terraform output -raw kafka_bootstrap_endpoint 2>/dev/null | cut -d':' -f1)
    
    if [ -z "$BOOTSTRAP" ]; then
        echo -e "${YELLOW}Uso: $0 <bootstrap_server> [flink_endpoint]${NC}"
        echo -e "Exemplo: $0 lkc-abc123.us-east-1.aws.private.confluent.cloud"
        exit 1
    else
        echo -e "${GREEN}Bootstrap server encontrado: $BOOTSTRAP${NC}"
    fi
else
    BOOTSTRAP=$1
fi

# Obter endpoint Flink
FLINK_ENDPOINT=$2

# Extrair região e domínio base
REGION=$(echo $BOOTSTRAP | cut -d'.' -f2)
DOMAIN_BASE=$(echo $BOOTSTRAP | cut -d'.' -f2-)

echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}   Verificação de Conectividade Direta - Confluent Cloud  ${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "Bootstrap Server: $BOOTSTRAP"
echo -e "Região: $REGION"
echo -e "Domínio Base: $DOMAIN_BASE"
if [ -n "$FLINK_ENDPOINT" ]; then
    echo -e "Flink Endpoint: $FLINK_ENDPOINT"
fi
echo -e "${BLUE}=========================================================${NC}"

# Verificar conectividade Kafka (porta 9092)
echo -e "\n${YELLOW}Verificando conectividade com Kafka (porta 9092)...${NC}"
KAFKA_RESULT=$(openssl s_client -connect $BOOTSTRAP:9092 -servername $BOOTSTRAP -verify_hostname $BOOTSTRAP </dev/null 2>&1)
KAFKA_STATUS=$?

if [ $KAFKA_STATUS -eq 0 ] && echo "$KAFKA_RESULT" | grep -q "BEGIN CERTIFICATE"; then
    echo -e "${GREEN}✓ Conectividade com Kafka estabelecida com sucesso!${NC}"
    echo -e "${YELLOW}Detalhes do certificado:${NC}"
    echo "$KAFKA_RESULT" | grep -E 'Verify return code|subject|issuer' | head -3
else
    echo -e "${RED}✗ Falha na conectividade com Kafka${NC}"
    echo -e "${YELLOW}Detalhes do erro:${NC}"
    echo "$KAFKA_RESULT" | grep -E 'error|fail|refused' | head -3
fi

# Verificar conectividade REST API (porta 443)
echo -e "\n${YELLOW}Verificando conectividade com REST API (porta 443)...${NC}"
REST_RESULT=$(openssl s_client -connect $BOOTSTRAP:443 -servername $BOOTSTRAP -verify_hostname $BOOTSTRAP </dev/null 2>&1)
REST_STATUS=$?

if [ $REST_STATUS -eq 0 ] && echo "$REST_RESULT" | grep -q "BEGIN CERTIFICATE"; then
    echo -e "${GREEN}✓ Conectividade com REST API estabelecida com sucesso!${NC}"
    echo -e "${YELLOW}Detalhes do certificado:${NC}"
    echo "$REST_RESULT" | grep -E 'Verify return code|subject|issuer' | head -3
else
    echo -e "${RED}✗ Falha na conectividade com REST API${NC}"
    echo -e "${YELLOW}Detalhes do erro:${NC}"
    echo "$REST_RESULT" | grep -E 'error|fail|refused' | head -3
fi

# Verificar conectividade Flink se fornecido
if [ -n "$FLINK_ENDPOINT" ]; then
    echo -e "\n${YELLOW}Verificando conectividade com Flink (porta 443)...${NC}"
    FLINK_RESULT=$(openssl s_client -connect $FLINK_ENDPOINT:443 -servername $FLINK_ENDPOINT -verify_hostname $FLINK_ENDPOINT </dev/null 2>&1)
    FLINK_STATUS=$?
    
    if [ $FLINK_STATUS -eq 0 ] && echo "$FLINK_RESULT" | grep -q "BEGIN CERTIFICATE"; then
        echo -e "${GREEN}✓ Conectividade com Flink estabelecida com sucesso!${NC}"
        echo -e "${YELLOW}Detalhes do certificado:${NC}"
        echo "$FLINK_RESULT" | grep -E 'Verify return code|subject|issuer' | head -3
    else
        echo -e "${RED}✗ Falha na conectividade com Flink${NC}"
        echo -e "${YELLOW}Detalhes do erro:${NC}"
        echo "$FLINK_RESULT" | grep -E 'error|fail|refused' | head -3
    fi
fi

# Verificar resolução DNS
echo -e "\n${YELLOW}Verificando resolução DNS...${NC}"
DNS_RESULT=$(dig +short $BOOTSTRAP 2>/dev/null)
if [ -n "$DNS_RESULT" ]; then
    echo -e "${GREEN}✓ DNS para $BOOTSTRAP resolvido: $DNS_RESULT${NC}"
else
    echo -e "${RED}✗ Falha na resolução DNS para $BOOTSTRAP${NC}"
    echo -e "${YELLOW}Sugestão: Adicione uma entrada no arquivo /etc/hosts${NC}"
    echo -e "Exemplo: <IP_DO_PROXY> $BOOTSTRAP"
fi

# Configurar hosts file automaticamente
echo -e "\n${YELLOW}Deseja configurar o arquivo /etc/hosts automaticamente? (s/n)${NC}"
read -p "Resposta: " CONFIGURE_HOSTS

if [[ "$CONFIGURE_HOSTS" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Digite o IP do proxy NGINX:${NC}"
    read -p "IP: " PROXY_IP
    
    if [ -n "$PROXY_IP" ]; then
        echo -e "${YELLOW}Adicionando entradas ao arquivo /etc/hosts...${NC}"
        
        # Backup do arquivo hosts
        sudo cp /etc/hosts /etc/hosts.bak.$(date +%Y%m%d%H%M%S)
        
        # Remover entradas antigas
        sudo sed -i.tmp '/# Confluent Cloud Private Link/d' /etc/hosts
        sudo sed -i.tmp "/$DOMAIN_BASE/d" /etc/hosts
        sudo rm -f /etc/hosts.tmp
        
        # Adicionar novas entradas
        echo "" | sudo tee -a /etc/hosts
        echo "# Confluent Cloud Private Link - Configurado em $(date)" | sudo tee -a /etc/hosts
        echo "$PROXY_IP $BOOTSTRAP" | sudo tee -a /etc/hosts
        echo "$PROXY_IP kafka-rest.$DOMAIN_BASE" | sudo tee -a /etc/hosts
        echo "$PROXY_IP schema-registry.$DOMAIN_BASE" | sudo tee -a /etc/hosts
        echo "$PROXY_IP ksqldb.$DOMAIN_BASE" | sudo tee -a /etc/hosts
        echo "$PROXY_IP connect.$DOMAIN_BASE" | sudo tee -a /etc/hosts
        
        if [ -n "$FLINK_ENDPOINT" ]; then
            echo "$PROXY_IP $FLINK_ENDPOINT" | sudo tee -a /etc/hosts
        fi
        
        echo -e "${GREEN}Arquivo /etc/hosts configurado com sucesso!${NC}"
    else
        echo -e "${RED}IP do proxy não fornecido. Configuração cancelada.${NC}"
    fi
fi

# Resumo e próximos passos
echo -e "\n${BLUE}=========================================================${NC}"
echo -e "${BLUE}                      Resumo                             ${NC}"
echo -e "${BLUE}=========================================================${NC}"

if [ $KAFKA_STATUS -eq 0 ] && [ $REST_STATUS -eq 0 ]; then
    echo -e "${GREEN}✓ Conectividade básica com Confluent Cloud estabelecida!${NC}"
    
    echo -e "\n${YELLOW}Configuração para cliente Kafka:${NC}"
    echo "bootstrap.servers=$BOOTSTRAP:9092"
    echo "security.protocol=SASL_SSL"
    echo "sasl.mechanism=PLAIN"
    echo "sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"\$API_KEY\" password=\"\$API_SECRET\";"
    
    echo -e "\n${YELLOW}Para criar um tópico via REST API:${NC}"
    echo "curl -X POST -H \"Content-Type: application/json\" \\"
    echo "  -H \"Authorization: Basic \$ENCODED_CREDENTIALS\" \\"
    echo "  --url https://$BOOTSTRAP/kafka/v3/clusters/\$CLUSTER_ID/topics \\"
    echo "  -d '{\"topic_name\":\"my-topic\",\"partitions_count\":6,\"replication_factor\":3}'"
    
    if [ -n "$FLINK_ENDPOINT" ] && [ $FLINK_STATUS -eq 0 ]; then
        echo -e "\n${YELLOW}Para acessar o Flink:${NC}"
        echo "curl -H \"Authorization: Bearer \$FLINK_TOKEN\" https://$FLINK_ENDPOINT/v1/sql/statements"
    fi
else
    echo -e "${RED}✗ Problemas de conectividade detectados${NC}"
    
    echo -e "\n${YELLOW}Possíveis soluções:${NC}"
    echo "1. Verifique se o Private Link está configurado corretamente"
    echo "2. Verifique se as entradas DNS estão configuradas"
    echo "3. Verifique se os security groups permitem tráfego nas portas 9092 e 443"
    echo "4. Se estiver usando proxy, verifique se o NGINX está configurado corretamente"
    
    echo -e "\n${YELLOW}Comando para testar novamente após ajustes:${NC}"
    echo "$0 $BOOTSTRAP $FLINK_ENDPOINT"
fi

exit 0