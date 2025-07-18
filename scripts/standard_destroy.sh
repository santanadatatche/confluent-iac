#!/bin/bash
# Script para executar o destroy padrão do Terraform

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Diretório do Terraform
if [ -z "$1" ]; then
  TF_DIR="terraform/environments/evoluservices"
else
  TF_DIR="$1"
fi

echo -e "${YELLOW}Executando destroy padrão no diretório: $TF_DIR${NC}"

# Verificar se o diretório existe
if [ ! -d "$TF_DIR" ]; then
  echo -e "${RED}Diretório $TF_DIR não encontrado!${NC}"
  exit 1
fi

# Navegar para o diretório
cd "$TF_DIR" || exit 1

# Executar terraform init
echo -e "${YELLOW}Inicializando Terraform...${NC}"
terraform init

# Executar terraform apply -destroy
echo -e "${YELLOW}Executando destroy via apply -destroy...${NC}"
terraform apply -destroy -auto-approve

# Verificar resultado
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Destroy executado com sucesso!${NC}"
else
  echo -e "${RED}Falha ao executar destroy. Verifique os logs acima.${NC}"
  exit 1
fi

exit 0