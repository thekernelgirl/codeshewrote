# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "source_region" {
  description = "The source region for cross-region replication"
}

variable "destination_region" {
  description = "The destination region for cross-region replication"
}

variable "table_name" {
  description = "Name of the DynamoDB table"
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name           = var.table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"
  range_key      = "range_key"
  
  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "range_key"
    type = "S"
  }

  replication_configuration {
    region = var.destination_region

    # This attribute is required for cross-region replication
    replica_provisioned_throughput_override {
      read_capacity_units  = 5
      write_capacity_units = 5
    }
  }

  server_side_encryption {
    enabled = true
  }
}

