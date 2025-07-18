#!/bin/bash
# Script para configurar DNS local para Confluent Cloud via Private Link

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Este script precisa ser executado como root para modificar o arquivo /etc/hosts${NC}"
  echo -e "${YELLOW}Tentando executar com sudo...${NC}"
  sudo "$0" "$@"
  exit $?
fi

# Verificar se o proxy IP e bootstrap server foram fornecidos
if [ -z "$1" ] || [ -z "$2" ]; then
  echo -e "${YELLOW}Uso: $0 <proxy_ip> <bootstrap_server> [flink_endpoint]${NC}"
  echo -e "Exemplo: $0 10.0.0.1 lkc-abc123.us-east-1.aws.private.confluent.cloud"
  echo -e "Exemplo com Flink: $0 10.0.0.1 lkc-abc123.us-east-1.aws.private.confluent.cloud flink-abc123.us-east-1.aws.confluent.cloud"
  exit 1
fi

PROXY_IP=$1
BOOTSTRAP_SERVER=$2
FLINK_ENDPOINT=$3

# Extrair o domínio base do bootstrap server
DOMAIN_BASE=$(echo $BOOTSTRAP_SERVER | cut -d'.' -f2-)

# Verificar se as entradas já existem no arquivo hosts
HOSTS_FILE="/etc/hosts"
BACKUP_FILE="/etc/hosts.bak.$(date +%Y%m%d%H%M%S)"

# Fazer backup do arquivo hosts
cp $HOSTS_FILE $BACKUP_FILE
echo -e "${GREEN}Backup do arquivo hosts criado em $BACKUP_FILE${NC}"

# Remover entradas antigas do Confluent Cloud se existirem
echo -e "${YELLOW}Removendo entradas antigas do Confluent Cloud...${NC}"
sed -i.tmp '/# Confluent Cloud Private Link/d' $HOSTS_FILE
sed -i.tmp "/$DOMAIN_BASE/d" $HOSTS_FILE
rm -f $HOSTS_FILE.tmp

# Adicionar novas entradas
echo -e "${YELLOW}Adicionando novas entradas DNS para Confluent Cloud...${NC}"
echo "" >> $HOSTS_FILE
echo "# Confluent Cloud Private Link - Configurado em $(date)" >> $HOSTS_FILE
echo "$PROXY_IP $BOOTSTRAP_SERVER" >> $HOSTS_FILE

# Adicionar entradas para outros serviços no mesmo domínio
echo "$PROXY_IP kafka-rest.$DOMAIN_BASE" >> $HOSTS_FILE
echo "$PROXY_IP schema-registry.$DOMAIN_BASE" >> $HOSTS_FILE
echo "$PROXY_IP ksqldb.$DOMAIN_BASE" >> $HOSTS_FILE
echo "$PROXY_IP connect.$DOMAIN_BASE" >> $HOSTS_FILE

# Adicionar entrada para Flink se fornecido
if [ -n "$FLINK_ENDPOINT" ]; then
  echo "$PROXY_IP $FLINK_ENDPOINT" >> $HOSTS_FILE
  echo -e "${GREEN}Entrada DNS para Flink adicionada: $FLINK_ENDPOINT -> $PROXY_IP${NC}"
fi

echo -e "${GREEN}Configuração DNS concluída com sucesso!${NC}"

# Testar a resolução DNS
echo -e "\n${YELLOW}Testando resolução DNS...${NC}"
ping -c 1 $BOOTSTRAP_SERVER > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ DNS para $BOOTSTRAP_SERVER está funcionando corretamente${NC}"
else
  echo -e "${RED}✗ Falha na resolução DNS para $BOOTSTRAP_SERVER${NC}"
fi

# Testar Flink se fornecido
if [ -n "$FLINK_ENDPOINT" ]; then
  ping -c 1 $FLINK_ENDPOINT > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ DNS para $FLINK_ENDPOINT está funcionando corretamente${NC}"
  else
    echo -e "${RED}✗ Falha na resolução DNS para $FLINK_ENDPOINT${NC}"
  fi
fi

# Instruções adicionais
echo -e "\n${YELLOW}=== Próximos Passos ===${NC}"
echo -e "1. Teste a conectividade com o script check_connectivity.sh:"
echo -e "   ./scripts/check_connectivity.sh $BOOTSTRAP_SERVER $PROXY_IP"

if [ -n "$FLINK_ENDPOINT" ]; then
  echo -e "2. Teste a conectividade com o Flink:"
  echo -e "   ./scripts/check_flink_connectivity.sh $FLINK_ENDPOINT $PROXY_IP"
fi

echo -e "\n${YELLOW}Para reverter as alterações no arquivo hosts:${NC}"
echo -e "sudo cp $BACKUP_FILE $HOSTS_FILE"

exit 0