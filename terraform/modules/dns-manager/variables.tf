variable "proxy_ip" {
  description = "Public IP of the proxy server"
  type        = string
}

variable "cluster_host" {
  description = "Kafka cluster hostname"
  type        = string
}

variable "flink_host" {
  description = "Flink hostname"
  type        = string
}