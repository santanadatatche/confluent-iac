# 🚀 Confluent Cloud Infrastructure as Code

Este projeto implementa uma infraestrutura completa do Confluent Cloud na AWS usando Terraform, incluindo conectores para MySQL, DynamoDB e S3, com proxy NGINX para acesso via Private Link.

## 📋 Índice

- [Arquitetura](#-arquitetura)
- [Pré-requisitos](#-pré-requisitos)
- [Módulos](#-módulos)
- [Como Executar](#-como-executar)
- [Configuração](#-configuração)
- [Conectores](#-conectores)
- [Proxy NGINX](#-proxy-nginx)
- [Troubleshooting](#-troubleshooting)
- [Segurança](#-segurança)

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   MySQL RDS     │    │  DynamoDB Table  │    │   S3 Bucket     │
│                 │    │                  │    │                 │
└─────────┬───────┘    └─────────┬────────┘    └─────────┬───────┘
          │                      │                       │
          │                      │                       │
          ▼                      ▼                       ▲
┌─────────────────────────────────────────────────────────────────┐
│                    Confluent Cloud                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │MySQL Source │  │DynamoDB Src │  │      Kafka Topic        │  │
│  │ Connector   │  │ Connector   │  │   topic-s3-sink-v2      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│                                                  │              │
│                                                  ▼              │
│                                    ┌─────────────────────────┐  │
│                                    │     S3 Sink Connector   │  │
│                                    └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                          ┌─────────────────┐
                          │  NGINX Proxy    │
                          │  (EC2 Instance) │
                          └─────────────────┘
                                    │
                                    ▼
                          ┌─────────────────┐
                          │   Your Local    │
                          │   Environment   │
                          └─────────────────┘
```

## 📋 Pré-requisitos

### Software Necessário
- [Terraform](https://www.terraform.io/downloads.html) >= 1.3
- Provider Confluent >= 2.32.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- Conta no [Confluent Cloud](https://confluent.cloud/)
- Acesso SSH configurado

### Recursos AWS Existentes
- VPC com subnets privadas
- RDS MySQL (opcional)
- DynamoDB Table (opcional)
- S3 Bucket (opcional)

### Credenciais Necessárias
- **Confluent Cloud API Key/Secret** (Cloud API)
- **AWS Account ID** (via secret no GitHub Actions)
- **VPC ID e Subnet IDs**

## 🧩 Módulos

### Core Modules

#### 1. **environment**
- **Propósito**: Cria o ambiente Confluent Cloud
- **Recursos**: `confluent_environment`
- **Outputs**: `environment_id`, `display_name`

#### 2. **kafka-cluster**
- **Propósito**: Provisiona cluster Kafka Enterprise
- **Recursos**: `confluent_kafka_cluster`
- **Tipos Suportados**: BASIC, STANDARD, ENTERPRISE, DEDICATED, FREIGHT
- **Outputs**: `cluster_id`, `bootstrap_endpoint`, `rest_endpoint`, `crn_pattern`

#### 3. **service-account**
- **Propósito**: Cria service account para conectores
- **Recursos**: `confluent_service_account`
- **Outputs**: `id`, `api_version`, `kind`

#### 4. **api-key**
- **Propósito**: Gera API keys para autenticação Kafka
- **Recursos**: `confluent_api_key`
- **Outputs**: `kafka_api_key`, `kafka_api_secret` (sensitive)

#### 5. **role-binding**
- **Propósito**: Atribui permissões ao service account
- **Recursos**: `confluent_role_binding`
- **Roles**: CloudClusterAdmin, DeveloperWrite
- **Outputs**: `role_binding_id`

### Networking Modules

#### 6. **private-link-attachment**
- **Propósito**: Cria Private Link Attachment
- **Recursos**: `confluent_private_link_attachment`
- **Clouds**: AWS, Azure, GCP
- **Outputs**: `id`, `dns_domain`, `aws`

#### 7. **aws-privatelink-endpoint**
- **Propósito**: Configura VPC Endpoint na AWS
- **Recursos**: `aws_vpc_endpoint`, `aws_route53_zone`, `aws_security_group`
- **Outputs**: `vpc_endpoint_id`

#### 8. **private-link-attachment-connection**
- **Propósito**: Conecta Private Link Attachment ao VPC Endpoint
- **Recursos**: `confluent_private_link_attachment_connection`
- **Outputs**: `id`, `display_name`

#### 9. **public-proxy** ⭐
- **Propósito**: Proxy NGINX para acesso externo via Private Link
- **Recursos**: 
  - `aws_instance` (EC2)
  - `aws_security_group`
  - `aws_subnet`
  - `aws_route_table`
  - `tls_private_key` (SSH)
- **Peculiaridades**:
  - Configura NGINX com SNI routing
  - Gera chaves SSH automaticamente
  - Aguarda serviços estarem prontos
  - Configura DNS automaticamente
- **Outputs**: `proxy_public_ip`, `ssh_command`, `diagnosis_command`

### Data Modules

#### 10. **kafka-topic**
- **Propósito**: Cria tópicos Kafka
- **Recursos**: `confluent_kafka_topic`
- **Configurações**: retention, cleanup policy, partitions
- **Outputs**: `topic_name`, `topic_id`

#### 11. **kafka-connector**
- **Propósito**: Módulo genérico para conectores
- **Recursos**: `confluent_connector`
- **Tipos**: Source e Sink connectors
- **Outputs**: `connector_name`, `connector_id`

## 🚀 Como Executar

### 1. Clone o Repositório
```bash
git clone https://github.com/santanadatatche/confluent-iac.git
cd confluent-iac/terraform/environments/evoluservices
```

### 2. Configure as Variáveis
Copie e edite o arquivo de variáveis:
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Configure Credenciais

**AWS:**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
# Note: AWS region is automatically set to match Confluent region from terraform.tfvars
```

**Confluent Cloud:**
```bash
export CONFLUENT_CLOUD_API_KEY="your-confluent-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-confluent-api-secret"
```

**⚠️ Importante**: Nunca coloque credenciais no arquivo terraform.tfvars. Use sempre variáveis de ambiente.

### 4. Inicialize o Terraform
```bash
terraform init
```

### 5. Planeje a Execução
```bash
terraform plan -var-file=terraform.tfvars
```

### 6. Execute a Infraestrutura
```bash
terraform apply -var-file=terraform.tfvars
```

### 7. Configure DNS (Importante!)
Após a execução, execute o comando que aparece no output:
```bash
terraform output -raw hosts_command
# Execute o comando retornado
```

### 8. Destruir (quando necessário)
```bash
terraform destroy -var-file=terraform.tfvars
```

## ⚙️ Configuração

### Arquivo terraform.tfvars

```hcl
# === GERAL ===
environment_name = "staging"
cloud            = "AWS"
region           = "us-east-2"

# === AWS === 
# aws_account_id será fornecido via secret AWS_ACCOUNT_ID no GitHub Actions
aws_default_zones = [
    { "zone" = "us-east-2a", cidr = "172.30.1.0/16" },
    { "zone" = "us-east-2b", cidr = "172.30.2.0/16" },
    { "zone" = "us-east-2c", cidr = "172.30.3.0/16" }
]
aws_default_ami = "ami-0c55b159cbfafe1f0"

# === VPC ===
vpc_id = "vpc-xxxxxxxxx"
subnets_to_privatelink = {
  "use2-az1" = "subnet-xxxxxxxxx",
  "use2-az2" = "subnet-yyyyyyyyy",
  "use2-az3" = "subnet-zzzzzzzzz",
}

# === CLUSTER ===
cluster_name = "enterprise-aws-cluster"
cluster_type = "ENTERPRISE"
availability = "MULTI_ZONE"

# === TOPIC ===
topic_name = "topic-s3-sink-v2"
topic_partitions = 1
topic_config = {
  "cleanup.policy" = "delete"
  "retention.ms"   = "604800000"
}
```

## 🚀 Apache Flink

### Configuração Private Link
O Flink está configurado para usar o mesmo Private Link Attachment do Kafka:

- **Endpoint Privado**: Configurado dinamicamente baseado na região
- **Endpoint Público**: Configurado dinamicamente baseado na região
- **Acesso**: Via proxy NGINX com SNI routing

### Como Acessar
```bash
# Via Private Link (após configurar DNS)
curl -H "Authorization: Bearer <token>" https://$(terraform output -raw flink_private_endpoint)

# Verificar endpoint configurado
terraform output flink_private_endpoint
terraform output flink_public_endpoint
```

### Configuração no Confluent Cloud
1. Acesse o Confluent Cloud Console
2. Vá para **Flink** > **Settings** > **Networking**
3. Configure o **Private Endpoint** para sua região configurada
4. Selecione o Private Link Attachment criado

## 🔌 Conectores

### MySQL CDC Source Connector
- **Classe**: `MySqlCdcSourceV2`
- **Formato**: JSON
- **Tabelas**: `kafkalab.customers`, `kafkalab.orders`
- **Prefixo**: `mysql`
- **Transformações**: ExtractNewRecordState

### DynamoDB CDC Source Connector
- **Classe**: `DynamoDbCdcSource`
- **Formato**: AVRO
- **Tabela**: `lab_table`
- **Prefixo**: `dynamodb`
- **Modo**: SNAPSHOT_CDC

### S3 Sink Connector
- **Classe**: `S3_SINK`
- **Formato**: JSON
- **Intervalo**: DAILY
- **Flush Size**: 1000
- **Tolerância a Erros**: ALL

## 🌐 Proxy NGINX

### Funcionalidades
- **SNI Routing**: Roteia tráfego baseado no Server Name Indication
- **Portas**: 443 (HTTPS) e 9092 (Kafka)
- **SSL Preread**: Lê SNI sem descriptografar
- **Logs**: Stream routing logs detalhados
- **Flink Support**: Suporte ao Flink via Private Link

### Configuração Automática
- Instala e configura NGINX automaticamente
- Gera chaves SSH para acesso
- Configura Security Groups
- Aguarda serviços estarem prontos
- Testa conectividade das portas

### Acesso SSH
```bash
# Comando gerado automaticamente no output
ssh -i .ssh/terraform_aws_rsa ubuntu@<proxy-ip>
```

### Diagnóstico
```bash
# Comando gerado automaticamente no output
bash ../../scripts/diagnose_proxy.sh <proxy-ip> <cluster-hostname>
```

## 🔍 Troubleshooting

### Problemas Comuns

#### 1. DNS Resolution Failed
```bash
# Execute o comando de configuração DNS
terraform output -raw hosts_command
# Execute o comando retornado
```

#### 2. Connector Failed
- Verifique logs no Confluent Cloud Console
- Confirme credenciais e permissões
- Valide configurações de rede

#### 3. Proxy Connection Issues
```bash
# Teste conectividade
nc -zv <proxy-ip> 443
nc -zv <proxy-ip> 9092

# Verifique logs do NGINX
ssh -i .ssh/terraform_aws_rsa ubuntu@<proxy-ip>
sudo tail -f /var/log/nginx/stream-error.log
```

#### 4. Permission Denied
- Verifique role bindings
- Confirme service account permissions
- Aguarde propagação de permissões (30s)

### Logs Importantes
- **NGINX**: `/var/log/nginx/stream-*.log`
- **User Data**: `/var/log/user-data.log`
- **Confluent**: Console web do Confluent Cloud

## 🔒 Segurança e Melhores Práticas

### 🔐 Gerenciamento de Credenciais

#### Variáveis de Ambiente (Recomendado)
Este projeto foi configurado para usar variáveis de ambiente para todas as credenciais sensíveis:

```bash
# AWS Credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
# Note: AWS region matches Confluent region from terraform.tfvars

# Confluent Cloud Credentials
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"
```

#### ❌ O que NÃO fazer:
- Nunca coloque credenciais em arquivos `.tf` ou `.tfvars`
- Não commite credenciais no Git
- Evite hardcoding de secrets no código
- Não compartilhe credenciais via chat/email

#### ✅ O que fazer:
- Use variáveis de ambiente para credenciais
- Configure `.gitignore` para arquivos sensíveis
- Use ferramentas como AWS Secrets Manager em produção
- Implemente rotação automática de credenciais

### 🚀 CI/CD e Automação

#### GitHub Actions
O projeto inclui workflow automatizado em `.github/workflows/deploy.yml`:

**Secrets necessários no GitHub**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCOUNT_ID`
- `CONFLUENT_CLOUD_API_KEY`
- `CONFLUENT_CLOUD_API_SECRET`
- `MYSQL_PASSWORD`
- `CONNECTOR_AWS_ACCESS_KEY`
- `CONNECTOR_AWS_SECRET_KEY`
- `CONNECTOR_DYNAMODB_ACCESS_KEY`
- `CONNECTOR_DYNAMODB_SECRET_KEY`

**Comportamento**:
- **Pull Request**: Executa `terraform plan`
- **Push na main**: Executa `terraform apply`
- **Manual**: Via "Run workflow"

### 🛡️ Segurança de Rede

#### Private Link Security
- **Isolamento de Rede**: Tráfego nunca sai da AWS backbone
- **DNS Privado**: Resolução via Route53 private zones
- **Security Groups**: Acesso restrito por IP/CIDR
- **VPC Endpoints**: Comunicação privada entre serviços

#### Proxy Security
- **SNI Routing**: Inspeção de certificados sem descriptografia
- **IP Whitelisting**: Acesso SSH apenas do IP público atual
- **Chaves SSH**: Geradas automaticamente pelo Terraform
- **Logs Detalhados**: Monitoramento de todas as conexões

### 🔑 Controle de Acesso

#### Service Accounts
- **Service Accounts Específicos**: Um por função/ambiente
- **Roles Granulares**: Permissões mínimas necessárias
- **Scoped Access**: Limitado a recursos específicos
- **Time-based Access**: Rotação regular de credenciais

### 📊 Monitoramento e Auditoria

#### Logs Importantes
```bash
# NGINX Proxy Logs
sudo tail -f /var/log/nginx/stream-access.log
sudo tail -f /var/log/nginx/stream-error.log

# AWS CloudTrail
aws logs describe-log-groups --log-group-name-prefix "/aws/"
```

### 📋 Checklist de Segurança

#### Antes do Deploy
- [ ] Credenciais configuradas via variáveis de ambiente
- [ ] `.gitignore` configurado para arquivos sensíveis
- [ ] Security Groups com acesso mínimo necessário
- [ ] VPC e subnets adequadamente configuradas

#### Após o Deploy
- [ ] Testar conectividade e funcionalidade
- [ ] Verificar logs de acesso e erros
- [ ] Confirmar que credenciais não estão expostas
- [ ] Configurar monitoramento e alertas

#### Manutenção Regular
- [ ] Rotacionar credenciais mensalmente
- [ ] Revisar logs de auditoria
- [ ] Atualizar dependências e providers
- [ ] Testar procedimentos de backup/restore

## 📊 Outputs Importantes

```bash
# Informações do cluster
terraform output kafka_cluster_id
terraform output kafka_bootstrap_endpoint
terraform output kafka_rest_endpoint

# Informações do proxy
terraform output proxy_public_ip
terraform output proxy_ssh_command

# Comandos úteis
terraform output hosts_command
terraform output proxy_diagnosis_command

# Credenciais (sensíveis)
terraform output service_account_manager_api_key
terraform output service_account_manager_api_secret
```

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📚 Referências Oficiais

### Confluent Cloud Documentation
- [Service Accounts & API Keys](https://docs.confluent.io/cloud/current/security/authenticate/workload-identities/service-accounts/api-keys/overview.html#ccloud-api-keys)
- [Private Networking Overview](https://docs.confluent.io/cloud/current/networking/ccloud-console-access.html)
- [Console Access Networking](https://docs.confluent.io/cloud/current/networking/ccloud-console-access.html#ccloud-console-access-networking)
- [Flink Private Networking](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/private-networking.html#flink-sql-enable-private-networking-pla)
- [AWS Private Link Service ID](https://docs.confluent.io/cloud/current/_images/aws-privatelink-service-id.png)

### Terraform Provider
- [Confluent Terraform Provider](https://registry.terraform.io/providers/confluentinc/confluent/latest)

### Connectors Documentation
- [MySQL CDC Source Connector v2](https://docs.confluent.io/cloud/current/connectors/cc-mysql-source-cdc-v2-debezium/cc-mysql-source-cdc-v2-debezium.html#cc-mysql-cdc-source-v2-debezium-custom-offsets)
- [DynamoDB CDC Source Connector](https://docs.confluent.io/cloud/current/connectors/cc-amazon-dynamodb-cdc-source.html?ajs_aid=ff022b43-854a-4110-af31-26220e3ee926&ajs_uid=4101400#configuration-properties)
- [AWS Networking for Connectors](https://docs.confluent.io/cloud/current/connectors/networking/aws-eap-1st-party.html)

### Project Repository
- [Datatche Confluent IAC](https://github.com/santanadatatche/confluent-iac)

## 📝 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

Copyright (c) 2025 **Datatche Inc**

---

**⚠️ Importante**: Este projeto cria recursos pagos no Confluent Cloud e AWS. Monitore os custos e destrua recursos quando não necessários.