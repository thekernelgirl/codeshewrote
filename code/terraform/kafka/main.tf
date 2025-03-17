# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

resource "aws_msk_cluster" "kafka_cluster" {
  cluster_name = "my-kafka-cluster"
  kafka_version = "2.8.1"  # Update with the desired Kafka version

  broker_node_group_info {
    instance_type = "kafka.m5.large"  # Update with the desired instance type
    client_subnets = ["subnet-12345678", "subnet-87654321"]  # Update with the desired subnet IDs
    security_groups = ["sg-12345678"]  # Update with the desired security group IDs
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "PLAINTEXT"
      in_cluster = "TLS"
    }
  }

  enhanced_monitoring = "DEFAULT"
  number_of_broker_nodes = 3  # Update with the desired number of broker nodes
}

