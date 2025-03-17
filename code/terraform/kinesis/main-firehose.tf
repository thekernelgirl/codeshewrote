# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "delivery_stream_name" {
  description = "Name of the Kinesis Data Firehose delivery stream"
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket to deliver data"
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_delivery_stream" {
  name        = var.delivery_stream_name
  destination {
    s3_configuration {
      role_arn     = "arn:aws:iam::123456789012:role/firehose_delivery_role"  # Update with your IAM role ARN
      bucket_arn   = var.s3_bucket_arn
      prefix       = "firehose/"  # Update with your desired S3 prefix
      buffer_size  = 128
      buffer_interval = 300
    }
  }
}

