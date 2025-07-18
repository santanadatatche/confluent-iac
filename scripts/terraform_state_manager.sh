#!/bin/bash
# Script para gerenciar o estado do Terraform de forma segura

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar se o Terraform está instalado
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform não está instalado. Por favor, instale-o primeiro.${NC}"
    exit 1
fi

# Diretório de trabalho
WORK_DIR=$(pwd)
echo -e "${BLUE}Diretório de trabalho: $WORK_DIR${NC}"

# Listar recursos no estado
list_resources() {
    echo -e "${YELLOW}Listando recursos no estado do Terraform...${NC}"
    terraform state list
}

# Mostrar detalhes de um recurso
show_resource() {
    if [ -z "$1" ]; then
        echo -e "${RED}Especifique o endereço do recurso.${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Mostrando detalhes do recurso: $1${NC}"
    terraform state show "$1"
}

# Remover um recurso do estado
remove_resource() {
    if [ -z "$1" ]; then
        echo -e "${RED}Especifique o endereço do recurso.${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Removendo recurso do estado: $1${NC}"
    echo -e "${RED}ATENÇÃO: Isso não destrói o recurso, apenas o remove do estado do Terraform.${NC}"
    read -p "Tem certeza que deseja continuar? (s/n): " CONFIRM
    
    if [[ "$CONFIRM" =~ ^[Ss]$ ]]; then
        terraform state rm "$1"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Recurso removido com sucesso.${NC}"
        else
            echo -e "${RED}Falha ao remover o recurso.${NC}"
        fi
    else
        echo -e "${YELLOW}Operação cancelada.${NC}"
    fi
}

# Fazer backup do estado
backup_state() {
    BACKUP_FILE="terraform.tfstate.backup.$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}Criando backup do estado em: $BACKUP_FILE${NC}"
    cp terraform.tfstate $BACKUP_FILE
    echo -e "${GREEN}Backup criado com sucesso.${NC}"
}

# Importar um recurso para o estado
import_resource() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Especifique o endereço do recurso e o ID.${NC}"
        echo -e "${YELLOW}Exemplo: module.kafka-cluster.confluent_kafka_cluster.cluster lkc-abc123${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Importando recurso para o estado: $1 (ID: $2)${NC}"
    terraform import "$1" "$2"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Recurso importado com sucesso.${NC}"
    else
        echo -e "${RED}Falha ao importar o recurso.${NC}"
    fi
}

# Verificar recursos problemáticos
check_problems() {
    echo -e "${YELLOW}Verificando recursos problemáticos...${NC}"
    terraform plan -detailed-exitcode
    
    case $? in
        0)
            echo -e "${GREEN}Nenhuma alteração necessária.${NC}"
            ;;
        1)
            echo -e "${RED}Erro ao executar o plano.${NC}"
            ;;
        2)
            echo -e "${YELLOW}Alterações necessárias detectadas.${NC}"
            ;;
    esac
}

# Menu principal
show_menu() {
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "${BLUE}           Gerenciador de Estado do Terraform           ${NC}"
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "1. Listar recursos no estado"
    echo -e "2. Mostrar detalhes de um recurso"
    echo -e "3. Remover um recurso do estado"
    echo -e "4. Fazer backup do estado atual"
    echo -e "5. Importar um recurso para o estado"
    echo -e "6. Verificar recursos problemáticos"
    echo -e "7. Sair"
    echo -e "${BLUE}=========================================================${NC}"
}

# Loop principal
while true; do
    show_menu
    read -p "Escolha uma opção (1-7): " OPTION
    
    case $OPTION in
        1)
            list_resources
            ;;
        2)
            read -p "Digite o endereço do recurso: " RESOURCE_ADDR
            show_resource "$RESOURCE_ADDR"
            ;;
        3)
            read -p "Digite o endereço do recurso a ser removido: " RESOURCE_ADDR
            remove_resource "$RESOURCE_ADDR"
            ;;
        4)
            backup_state
            ;;
        5)
            read -p "Digite o endereço do recurso: " RESOURCE_ADDR
            read -p "Digite o ID do recurso: " RESOURCE_ID
            import_resource "$RESOURCE_ADDR" "$RESOURCE_ID"
            ;;
        6)
            check_problems
            ;;
        7)
            echo -e "${GREEN}Saindo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
done