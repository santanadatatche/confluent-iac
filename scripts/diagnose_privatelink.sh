#!/bin/bash
# Script principal para diagnóstico de problemas com Private Link no Confluent Cloud

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}   Diagnóstico de Private Link para Confluent Cloud      ${NC}"
echo -e "${BLUE}=========================================================${NC}"

# Verificar se o Terraform está disponível
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform não está instalado ou não está no PATH.${NC}"
    echo -e "${YELLOW}Por favor, instale o Terraform: https://www.terraform.io/downloads.html${NC}"
    exit 1
fi

# Tentar obter informações do Terraform
echo -e "\n${YELLOW}Obtendo informações do Terraform...${NC}"
BOOTSTRAP_SERVER=$(terraform output -raw kafka_bootstrap_endpoint 2>/dev/null | cut -d':' -f1)
PROXY_IP=$(terraform output -raw proxy_public_ip 2>/dev/null)
FLINK_ENDPOINT=$(terraform output -raw flink_private_endpoint 2>/dev/null)

if [ -z "$BOOTSTRAP_SERVER" ]; then
    echo -e "${YELLOW}Não foi possível obter o bootstrap server do Terraform.${NC}"
    read -p "Digite o bootstrap server (ex: lkc-abc123.us-east-1.aws.private.confluent.cloud): " BOOTSTRAP_SERVER
fi

if [ -z "$PROXY_IP" ]; then
    echo -e "${YELLOW}Não foi possível obter o IP do proxy do Terraform.${NC}"
    read -p "Digite o IP do proxy NGINX (deixe em branco para conexão direta): " PROXY_IP
fi

# Menu de opções
echo -e "\n${BLUE}=========================================================${NC}"
echo -e "${BLUE}                     Menu de Diagnóstico                 ${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "1. Verificar conectividade com Kafka (porta 9092 e 443)"
echo -e "2. Verificar conectividade com Flink (se disponível)"
echo -e "3. Configurar DNS local (requer sudo)"
echo -e "4. Verificar configuração do proxy NGINX"
echo -e "5. Executar diagnóstico completo"
echo -e "6. Sair"
echo -e "${BLUE}=========================================================${NC}"

read -p "Escolha uma opção (1-6): " OPTION

case $OPTION in
    1)
        echo -e "\n${YELLOW}Verificando conectividade com Kafka...${NC}"
        $SCRIPT_DIR/check_connectivity.sh "$BOOTSTRAP_SERVER" "$PROXY_IP"
        ;;
    2)
        if [ -z "$FLINK_ENDPOINT" ]; then
            echo -e "${YELLOW}Endpoint Flink não encontrado no Terraform.${NC}"
            read -p "Digite o endpoint Flink (ex: flink-abc123.us-east-1.aws.confluent.cloud): " FLINK_ENDPOINT
        fi
        
        if [ -n "$FLINK_ENDPOINT" ]; then
            echo -e "\n${YELLOW}Verificando conectividade com Flink...${NC}"
            read -p "Digite o token de autenticação (opcional): " BEARER_TOKEN
            $SCRIPT_DIR/check_flink_connectivity.sh "$FLINK_ENDPOINT" "$PROXY_IP" "$BEARER_TOKEN"
        else
            echo -e "${RED}Endpoint Flink não fornecido. Pulando verificação.${NC}"
        fi
        ;;
    3)
        echo -e "\n${YELLOW}Configurando DNS local...${NC}"
        if [ -z "$PROXY_IP" ]; then
            echo -e "${RED}IP do proxy é necessário para configurar DNS local.${NC}"
            read -p "Digite o IP do proxy NGINX: " PROXY_IP
        fi
        
        if [ -n "$PROXY_IP" ] && [ -n "$BOOTSTRAP_SERVER" ]; then
            sudo $SCRIPT_DIR/setup_dns.sh "$PROXY_IP" "$BOOTSTRAP_SERVER" "$FLINK_ENDPOINT"
        else
            echo -e "${RED}Informações insuficientes para configurar DNS.${NC}"
        fi
        ;;
    4)
        if [ -z "$PROXY_IP" ]; then
            echo -e "${RED}IP do proxy é necessário para verificar configuração.${NC}"
            read -p "Digite o IP do proxy NGINX: " PROXY_IP
        fi
        
        if [ -n "$PROXY_IP" ]; then
            echo -e "\n${YELLOW}Verificando configuração do proxy NGINX...${NC}"
            echo -e "${YELLOW}Comandos para verificar configuração:${NC}"
            echo -e "ssh -i .ssh/terraform_aws_rsa ubuntu@$PROXY_IP 'sudo cat /etc/nginx/nginx.conf'"
            echo -e "ssh -i .ssh/terraform_aws_rsa ubuntu@$PROXY_IP 'sudo systemctl status nginx'"
            echo -e "ssh -i .ssh/terraform_aws_rsa ubuntu@$PROXY_IP 'sudo tail -f /var/log/nginx/stream-access.log'"
            
            read -p "Deseja executar esses comandos agora? (s/n): " RUN_COMMANDS
            if [[ "$RUN_COMMANDS" =~ ^[Ss]$ ]]; then
                echo -e "\n${YELLOW}Verificando status do NGINX:${NC}"
                ssh -i .ssh/terraform_aws_rsa ubuntu@$PROXY_IP 'sudo systemctl status nginx' || echo -e "${RED}Falha ao conectar via SSH.${NC}"
            fi
        else
            echo -e "${RED}IP do proxy não fornecido.${NC}"
        fi
        ;;
    5)
        echo -e "\n${YELLOW}Executando diagnóstico completo...${NC}"
        
        echo -e "\n${BLUE}1. Verificando conectividade com Kafka...${NC}"
        $SCRIPT_DIR/check_connectivity.sh "$BOOTSTRAP_SERVER" "$PROXY_IP"
        
        if [ -n "$FLINK_ENDPOINT" ]; then
            echo -e "\n${BLUE}2. Verificando conectividade com Flink...${NC}"
            $SCRIPT_DIR/check_flink_connectivity.sh "$FLINK_ENDPOINT" "$PROXY_IP"
        fi
        
        if [ -n "$PROXY_IP" ]; then
            echo -e "\n${BLUE}3. Verificando configuração do proxy NGINX...${NC}"
            echo -e "${YELLOW}Tentando verificar status do NGINX:${NC}"
            ssh -i .ssh/terraform_aws_rsa ubuntu@$PROXY_IP 'sudo systemctl status nginx' 2>/dev/null || echo -e "${RED}Falha ao conectar via SSH.${NC}"
        fi
        
        echo -e "\n${BLUE}4. Verificando DNS...${NC}"
        echo -e "${YELLOW}Resolução DNS para $BOOTSTRAP_SERVER:${NC}"
        dig +short $BOOTSTRAP_SERVER || echo -e "${RED}Falha na resolução DNS.${NC}"
        
        echo -e "\n${BLUE}=========================================================${NC}"
        echo -e "${BLUE}                 Resumo do Diagnóstico                   ${NC}"
        echo -e "${BLUE}=========================================================${NC}"
        echo -e "Bootstrap Server: $BOOTSTRAP_SERVER"
        echo -e "Proxy IP: ${PROXY_IP:-"Não configurado"}"
        echo -e "Flink Endpoint: ${FLINK_ENDPOINT:-"Não configurado"}"
        
        echo -e "\n${YELLOW}Recomendações:${NC}"
        echo -e "1. Se houver problemas de DNS, execute: sudo $SCRIPT_DIR/setup_dns.sh $PROXY_IP $BOOTSTRAP_SERVER $FLINK_ENDPOINT"
        echo -e "2. Se houver problemas de conectividade, verifique security groups e configuração do NGINX"
        echo -e "3. Para mais informações, consulte a documentação oficial: https://docs.confluent.io/cloud/current/networking/ccloud-console-access.html"
        ;;
    6)
        echo -e "${GREEN}Saindo...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Opção inválida.${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}Diagnóstico concluído.${NC}"
exit 0