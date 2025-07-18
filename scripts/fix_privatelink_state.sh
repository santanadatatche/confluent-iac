#!/bin/bash
# Script para corrigir problemas específicos de Private Link no estado do Terraform

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

# Fazer backup do estado atual
BACKUP_FILE="terraform.tfstate.backup.$(date +%Y%m%d%H%M%S)"
echo -e "${YELLOW}Criando backup do estado em: $BACKUP_FILE${NC}"
cp terraform.tfstate $BACKUP_FILE 2>/dev/null || echo -e "${RED}Não foi possível criar backup. Verifique se o arquivo terraform.tfstate existe.${NC}"

# Listar recursos no estado
echo -e "${YELLOW}Listando recursos no estado do Terraform...${NC}"
RESOURCES=$(terraform state list 2>/dev/null)

if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao listar recursos. Verifique se você está no diretório correto.${NC}"
    exit 1
fi

# Identificar recursos de Private Link
echo -e "${YELLOW}Identificando recursos de Private Link...${NC}"
PRIVATELINK_RESOURCES=$(echo "$RESOURCES" | grep -E 'private_link|privatelink')

if [ -z "$PRIVATELINK_RESOURCES" ]; then
    echo -e "${YELLOW}Nenhum recurso de Private Link encontrado no estado.${NC}"
    
    # Verificar se há recursos de rede
    NETWORK_RESOURCES=$(echo "$RESOURCES" | grep -E 'network|vpc|subnet|endpoint')
    
    if [ -n "$NETWORK_RESOURCES" ]; then
        echo -e "${YELLOW}Recursos de rede encontrados:${NC}"
        echo "$NETWORK_RESOURCES"
    fi
else
    echo -e "${YELLOW}Recursos de Private Link encontrados:${NC}"
    echo "$PRIVATELINK_RESOURCES"
    
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "${BLUE}           Opções para corrigir o estado                 ${NC}"
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "1. Remover todos os recursos de Private Link do estado"
    echo -e "2. Remover recursos de Private Link selecionados"
    echo -e "3. Tentar reimportar recursos de Private Link"
    echo -e "4. Sair sem fazer alterações"
    echo -e "${BLUE}=========================================================${NC}"
    
    read -p "Escolha uma opção (1-4): " OPTION
    
    case $OPTION in
        1)
            echo -e "${YELLOW}Removendo todos os recursos de Private Link do estado...${NC}"
            echo -e "${RED}ATENÇÃO: Isso não destrói os recursos, apenas os remove do estado do Terraform.${NC}"
            read -p "Tem certeza que deseja continuar? (s/n): " CONFIRM
            
            if [[ "$CONFIRM" =~ ^[Ss]$ ]]; then
                for RESOURCE in $PRIVATELINK_RESOURCES; do
                    echo -e "${YELLOW}Removendo: $RESOURCE${NC}"
                    terraform state rm "$RESOURCE" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}Recurso removido com sucesso.${NC}"
                    else
                        echo -e "${RED}Falha ao remover o recurso. Tentando abordagem alternativa...${NC}"
                        # Abordagem alternativa usando grep para evitar erros de correspondência exata
                        RESOURCE_ESCAPED=$(echo "$RESOURCE" | sed 's/\[/\\[/g' | sed 's/\]/\\]/g')
                        terraform state list | grep -E "$RESOURCE_ESCAPED" | while read -r MATCH; do
                            echo -e "${YELLOW}Tentando remover: $MATCH${NC}"
                            terraform state rm "$MATCH" 2>/dev/null
                        done
                    fi
                done
                echo -e "${GREEN}Operação concluída.${NC}"
            else
                echo -e "${YELLOW}Operação cancelada.${NC}"
            fi
            ;;
        2)
            echo -e "${YELLOW}Selecione os recursos a serem removidos:${NC}"
            PS3="Selecione um recurso (0 para concluir): "
            select RESOURCE in $PRIVATELINK_RESOURCES "Concluir"; do
                if [ "$REPLY" = "0" ] || [ "$RESOURCE" = "Concluir" ]; then
                    break
                fi
                
                echo -e "${YELLOW}Removendo: $RESOURCE${NC}"
                terraform state rm "$RESOURCE" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}Recurso removido com sucesso.${NC}"
                else
                    echo -e "${RED}Falha ao remover o recurso.${NC}"
                fi
            done
            echo -e "${GREEN}Operação concluída.${NC}"
            ;;
        3)
            echo -e "${YELLOW}Para reimportar recursos, você precisará dos IDs dos recursos.${NC}"
            echo -e "${YELLOW}Consulte o console do Confluent Cloud para obter os IDs.${NC}"
            
            read -p "Deseja continuar? (s/n): " CONTINUE
            if [[ "$CONTINUE" =~ ^[Ss]$ ]]; then
                for RESOURCE in $PRIVATELINK_RESOURCES; do
                    echo -e "${YELLOW}Recurso: $RESOURCE${NC}"
                    read -p "Digite o ID do recurso (deixe em branco para pular): " RESOURCE_ID
                    
                    if [ -n "$RESOURCE_ID" ]; then
                        echo -e "${YELLOW}Importando: $RESOURCE com ID: $RESOURCE_ID${NC}"
                        terraform import "$RESOURCE" "$RESOURCE_ID" 2>/dev/null
                        if [ $? -eq 0 ]; then
                            echo -e "${GREEN}Recurso importado com sucesso.${NC}"
                        else
                            echo -e "${RED}Falha ao importar o recurso.${NC}"
                        fi
                    else
                        echo -e "${YELLOW}Pulando recurso.${NC}"
                    fi
                done
                echo -e "${GREEN}Operação concluída.${NC}"
            else
                echo -e "${YELLOW}Operação cancelada.${NC}"
            fi
            ;;
        4)
            echo -e "${GREEN}Saindo sem fazer alterações.${NC}"
            ;;
        *)
            echo -e "${RED}Opção inválida.${NC}"
            ;;
    esac
fi

# Verificar se há recursos de Flink
FLINK_RESOURCES=$(echo "$RESOURCES" | grep -E 'flink')

if [ -n "$FLINK_RESOURCES" ]; then
    echo -e "\n${YELLOW}Recursos de Flink encontrados:${NC}"
    echo "$FLINK_RESOURCES"
    
    read -p "Deseja gerenciar recursos de Flink também? (s/n): " MANAGE_FLINK
    
    if [[ "$MANAGE_FLINK" =~ ^[Ss]$ ]]; then
        echo -e "${BLUE}=========================================================${NC}"
        echo -e "${BLUE}           Opções para recursos de Flink                 ${NC}"
        echo -e "${BLUE}=========================================================${NC}"
        echo -e "1. Remover todos os recursos de Flink do estado"
        echo -e "2. Remover recursos de Flink selecionados"
        echo -e "3. Sair sem fazer alterações"
        echo -e "${BLUE}=========================================================${NC}"
        
        read -p "Escolha uma opção (1-3): " FLINK_OPTION
        
        case $FLINK_OPTION in
            1)
                echo -e "${YELLOW}Removendo todos os recursos de Flink do estado...${NC}"
                for RESOURCE in $FLINK_RESOURCES; do
                    echo -e "${YELLOW}Removendo: $RESOURCE${NC}"
                    terraform state rm "$RESOURCE" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}Recurso removido com sucesso.${NC}"
                    else
                        echo -e "${RED}Falha ao remover o recurso.${NC}"
                    fi
                done
                echo -e "${GREEN}Operação concluída.${NC}"
                ;;
            2)
                echo -e "${YELLOW}Selecione os recursos a serem removidos:${NC}"
                PS3="Selecione um recurso (0 para concluir): "
                select RESOURCE in $FLINK_RESOURCES "Concluir"; do
                    if [ "$REPLY" = "0" ] || [ "$RESOURCE" = "Concluir" ]; then
                        break
                    fi
                    
                    echo -e "${YELLOW}Removendo: $RESOURCE${NC}"
                    terraform state rm "$RESOURCE" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}Recurso removido com sucesso.${NC}"
                    else
                        echo -e "${RED}Falha ao remover o recurso.${NC}"
                    fi
                done
                echo -e "${GREEN}Operação concluída.${NC}"
                ;;
            3)
                echo -e "${GREEN}Saindo sem fazer alterações nos recursos de Flink.${NC}"
                ;;
            *)
                echo -e "${RED}Opção inválida.${NC}"
                ;;
        esac
    fi
fi

# Verificar o estado atual
echo -e "\n${YELLOW}Verificando o estado atual do Terraform...${NC}"
terraform state list 2>/dev/null

echo -e "\n${YELLOW}Próximos passos recomendados:${NC}"
echo -e "1. Execute 'terraform plan' para verificar o estado atual"
echo -e "2. Se necessário, execute 'terraform import' para reimportar recursos"
echo -e "3. Execute 'terraform apply' para reconciliar o estado"

echo -e "\n${GREEN}Script concluído. Backup do estado original salvo em: $BACKUP_FILE${NC}"
exit 0