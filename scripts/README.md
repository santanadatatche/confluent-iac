# Scripts para Confluent Cloud

Este diretório contém scripts para gerenciar a infraestrutura do Confluent Cloud.

## Scripts de Conectividade

### 1. `direct_connectivity.sh`

Script para verificar e estabelecer conectividade direta com o Confluent Cloud.

```bash
./scripts/direct_connectivity.sh <bootstrap_server> [flink_endpoint]

# Exemplo:
./scripts/direct_connectivity.sh lkc-abc123.us-east-1.aws.private.confluent.cloud
```

### 2. `setup_dns.sh`

Script para configurar entradas DNS locais para Confluent Cloud e Flink.

```bash
sudo ./scripts/setup_dns.sh <proxy_ip> <bootstrap_server> [flink_endpoint]

# Exemplo:
sudo ./scripts/setup_dns.sh 10.0.0.1 lkc-abc123.us-east-1.aws.private.confluent.cloud
```

### 3. `nginx_sni_config.sh`

Script para configurar o NGINX com SNI para Confluent Cloud.

```bash
sudo ./scripts/nginx_sni_config.sh
```

## Scripts de Terraform

### 1. `standard_destroy.sh`

Script para executar o destroy padrão do Terraform usando `apply -destroy`.

```bash
./scripts/standard_destroy.sh [diretório_terraform]

# Exemplo:
./scripts/standard_destroy.sh terraform/environments/evoluservices
```

Este script:
- Inicializa o Terraform
- Executa `terraform apply -destroy -auto-approve`
- Usa o diretório padrão `terraform/environments/evoluservices` se nenhum for especificado

## GitHub Actions

Também foi adicionado um workflow do GitHub Actions para executar o destroy padrão:

- **terraform-destroy.yml**: Executa `terraform apply -destroy` para destruir a infraestrutura

Para usar:
1. Acesse a aba "Actions" no GitHub
2. Selecione o workflow "Terraform Destroy"
3. Clique em "Run workflow"
4. Selecione o ambiente desejado
5. Clique em "Run workflow"

## Solução de Problemas

### Problemas de Destroy

Se você encontrar erros durante o destroy:

1. Use o método padrão com `apply -destroy`:
   ```bash
   ./scripts/standard_destroy.sh
   ```

2. Ou execute manualmente:
   ```bash
   cd terraform/environments/evoluservices
   terraform apply -destroy -auto-approve
   ```

### Problemas de Conectividade

Consulte a documentação oficial:
- [Confluent Cloud Private Link](https://docs.confluent.io/cloud/current/networking/ccloud-console-access.html)