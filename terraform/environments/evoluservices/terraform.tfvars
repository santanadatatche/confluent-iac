# === GERAL ===
environment_name = "staging"
cloud            = "AWS"
region           = "us-east-2"

# === AWS === 
aws_default_zones =  [
    { "zone" = "us-east-2a", cidr = "172.30.1.0/16" },
    { "zone" = "us-east-2b", cidr = "172.30.2.0/16" },
    { "zone" = "us-east-2c", cidr = "172.30.3.0/16" }
  ]
aws_default_ami = "ami-0c55b159cbfafe1f0" # us-east-2

# === PRIVATE LINK ATTACHMENT CONNECTION ===
platt_display_name = "staging-aws-platt"
plattc_display_name = "staging-aws-plattc"

# === VPC ===
vpc_id                 = "vpc-004dd059facd2da59"
subnets_to_privatelink = {
  "use2-az1" = "subnet-0d983e27f872f0a5d",
  "use2-az2" = "subnet-0f7f71038b83e867e",
  "use2-az3" = "subnet-042e83d571b15aa47",
}

# === SERVICE ACCOUNT ===
service_account_name        = "app-manager"
api_key_name = "api-key-app-manager"
api_key_description = "Kafka API Key that is owned by 'app-manager' service account"
service_account_description = "Service Account to manage Kafka cluster"

# === ROLE BINDING ===
role_name   = "CloudClusterAdmin"

# === CLUSTER ===
cluster_name       = "enterprise-aws-cluster"
cluster_type       = "ENTERPRISE"
availability             = "MULTI_ZONE"
# CKU não usado em ENTERPRISE
cku = null

# === TOPIC ===
topic_name  = "topic-s3-sink-v2"
topic_partitions = 1
topic_config = {
  "cleanup.policy" = "delete"
  "retention.ms"   = "604800000"
}

# === CONNECTOR MYSQL SOURCE ===
mysql_source_config_nonsensitive = {
  "name"                               = "mysql-cdc-source-connector"  #Fixo
  "connector.class"                    = "MySqlCdcSourceV2"           #Fixo
  "tasks.max"                          = "1"                          #Fixo
  "database.hostname"                  = "mysql-kafka-lab.chk8gauacjmz.us-east-2.rds.amazonaws.com"  #Alterar
  "database.port"                      = "3306"                       #Fixo
  "database.user"                      = "admin"                      #Alterar
  "database.server.name"               = "mysql-server"               #Fixo
  "ssl.mode"                           = "required"                   #Fixo p/ Aurora
  "database.timezone"                  = "UTC"                        #Fixo
  "topic.prefix"                       = "mysql"                      #Fixo
  "output.data.format"                 = "JSON"                       #Fixo
  "kafka.auth.mode"                    = "KAFKA_API_KEY"              #Fixo
  "transforms"                         = "unwrap"                     #Fixo
  "transforms.unwrap.type"             = "io.debezium.transforms.ExtractNewRecordState"  #Fixo
  "transforms.unwrap.drop.tombstones"  = "false"                      #Fixo
  "transforms.unwrap.delete.handling.mode" = "rewrite"                #Fixo
  "database.server.id"                 = "85744"                      #Fixo - ID único para o conector
  "snapshot.mode"                      = "when_needed"                #Fixo para Aurora
  "snapshot.locking.mode"              = "none"                       #Fixo para Aurora
  "binlog.format"                      = "ROW"                        #Fixo para Aurora
  "database.include.list"              = "kafkalab"                   #Alterar
  "event.processing.failure.handling.mode" = "warn"                   #Fixo
  "inconsistent.schema.handling.mode"  = "warn"                       #Fixo
  "database.history.store.only.captured.tables.ddl" = "true"         #Fixo - Otimização
  "database.history.kafka.topic" = "mysql-history-topic"             #Fixo - Nome do tópico de histórico
}

# === CONNECTOR S3 SINK ===
s3_sink_config_nonsensitive = {
  "input.data.format"        = "JSON"                       #Fixo
  "connector.class"          = "S3_SINK"                    #Fixo
  "name"                     = "s3-sink-connector"          #Fixo
  "kafka.auth.mode"          = "SERVICE_ACCOUNT"            #Fixo
  "s3.bucket.name"           = "s3-kafka-lab"               # Alterar para seu bucket
  "output.data.format"       = "JSON"                       #Fixo
  "time.interval"            = "DAILY"                      #Fixo
  "flush.size"               = "1000"                       #Fixo
  "tasks.max"                = "1"                          #Fixo
  "errors.tolerance"         = "all"                        #Fixo
  "errors.deadletterqueue.topic.name" = ""                  #Fixo
  "errors.deadletterqueue.context.headers.enable" = "false" #Fixo
}

# === CONNECTOR DynamoDB SOURCE ===
dynamodb_source_config_nonsensitive = {
  "name"                     = "dynamodb-cdc-source-connector" #Fixo
  "connector.class"          = "DynamoDbCdcSource"            #Fixo
  "schema.context.name"      = "default"                      #Fixo
  "tasks.max"                = "1"                           #Fixo
  "kafka.auth.mode"          = "KAFKA_API_KEY"               #Fixo
  "aws.dynamodb.table.name"  = "lab_table"                   # Alterar para sua tabela
  "aws.dynamodb.region"      = "us-east-2"                   #Alterar
  "output.data.format"       = "AVRO"                        #Fixo
  "aws.dynamodb.prefix"      = "dynamodb"                    #Fixo
  "dynamodb.service.endpoint" = "https://dynamodb.us-east-2.amazonaws.com" #Alterar
  "dynamodb.table.discovery.mode" = "INCLUDELIST"            #Fixo
  "dynamodb.table.sync.mode" = "SNAPSHOT_CDC"                #Fixo
  "dynamodb.table.includelist" = "lab_table"                 # Alterar para sua tabela
  "max.batch.size" = "1000"                                  #Fixo
  "poll.linger.ms" = "5000"                                  #Fixo
  "dynamodb.snapshot.max.poll.records" = "1000"              #Fixo
  "dynamodb.cdc.checkpointing.table.prefix" = "connect-KCL-" #Fixo
  "dynamodb.cdc.table.billing.mode" = "PROVISIONED"          #Fixo
  "dynamodb.cdc.max.poll.records" = "5000"                   #Fixo
}