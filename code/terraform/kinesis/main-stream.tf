# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "stream_name" {
  description = "Name of the Kinesis stream"
}

variable "shard_count" {
  description = "Number of shards for the Kinesis stream"
  default     = 1  # Update with the desired shard count
}

resource "aws_kinesis_stream" "kinesis_stream" {
  name             = var.stream_name
  shard_count      = var.shard_count
}

