#!/bin/bash
# Script para configurar o NGINX com SNI para Confluent Cloud
# Esta é uma abordagem alternativa baseada na documentação oficial

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Este script precisa ser executado como root para instalar e configurar o NGINX${NC}"
  echo -e "${YELLOW}Tentando executar com sudo...${NC}"
  sudo "$0" "$@"
  exit $?
fi

# Instalar NGINX se não estiver instalado
if ! command -v nginx &> /dev/null; then
  echo -e "${YELLOW}NGINX não está instalado. Instalando...${NC}"
  apt update
  apt install -y nginx
fi

# Criar configuração NGINX com SNI
echo -e "${YELLOW}Configurando NGINX com SNI para Confluent Cloud...${NC}"

# Criar arquivo de configuração
cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

# Configuração para streaming (SNI)
stream {
    map $ssl_preread_server_name $targetBackend {
        default $ssl_preread_server_name;
    }

    # Configuração para Kafka (porta 9092)
    server {
        listen 9092;
        proxy_connect_timeout 1s;
        proxy_timeout 7200s;
        resolver 8.8.8.8;
        proxy_pass $targetBackend:9092;
        ssl_preread on;
    }

    # Configuração para REST API (porta 443)
    server {
        listen 443;
        proxy_connect_timeout 1s;
        proxy_timeout 7200s;
        resolver 8.8.8.8;
        proxy_pass $targetBackend:443;
        ssl_preread on;
    }

    log_format stream_routing '[$time_local] remote address $remote_addr '
                              'with SNI name "$ssl_preread_server_name" '
                              'proxied to "$upstream_addr" '
                              '$protocol $status $bytes_sent $bytes_received '
                              '$session_time';
    access_log /var/log/nginx/stream-access.log stream_routing;
    error_log /var/log/nginx/stream-error.log;
}

# Configuração HTTP básica
http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    gzip on;
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
    
    # Página de status simples
    server {
        listen 80;
        server_name localhost;
        
        location / {
            return 200 "NGINX Proxy para Confluent Cloud está funcionando!\n";
        }
        
        location /status {
            stub_status on;
            allow 127.0.0.1;
            deny all;
        }
    }
}
EOF

# Reiniciar NGINX
echo -e "${YELLOW}Reiniciando NGINX...${NC}"
systemctl restart nginx

# Verificar status
if systemctl is-active --quiet nginx; then
  echo -e "${GREEN}✓ NGINX configurado e iniciado com sucesso!${NC}"
else
  echo -e "${RED}✗ Falha ao iniciar NGINX. Verificando logs...${NC}"
  journalctl -u nginx --no-pager -n 20
  exit 1
fi

# Abrir portas no firewall se o UFW estiver ativo
if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
  echo -e "${YELLOW}Configurando firewall (UFW)...${NC}"
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw allow 9092/tcp
  echo -e "${GREEN}✓ Portas abertas no firewall${NC}"
fi

# Exibir IP do servidor
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "\n${GREEN}Servidor NGINX configurado com sucesso!${NC}"
echo -e "${YELLOW}IP do servidor: ${SERVER_IP}${NC}"

echo -e "\n${YELLOW}=== Próximos Passos ===${NC}"
echo -e "1. Configure o arquivo /etc/hosts em sua máquina local:"
echo -e "   ${SERVER_IP} seu-bootstrap-server.region.aws.confluent.cloud"
echo -e "   ${SERVER_IP} seu-flink-endpoint.region.aws.confluent.cloud"
echo -e "2. Teste a conectividade:"
echo -e "   openssl s_client -connect ${SERVER_IP}:9092 -servername seu-bootstrap-server.region.aws.confluent.cloud"
echo -e "3. Verifique os logs do NGINX se necessário:"
echo -e "   tail -f /var/log/nginx/stream-access.log"

exit 0