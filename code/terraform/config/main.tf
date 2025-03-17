# main.tf

variable "s3_bucket_name" {
  description = "Name of the S3 bucket where AWS Config records will be stored"
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic to which AWS Config notifications will be sent"
}

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

resource "aws_s3_bucket" "config_bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"
  versioning {
    enabled = true
  }
}

resource "aws_sns_topic" "config_topic" {
  name = "config-topic"
}

resource "aws_config_recorder" "config_recorder" {
  name     = "default"
  role_arn = aws_iam_role.config_role.arn
}

resource "aws_iam_role" "config_role" {
  name               = "config-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "config_managed_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
  role       = aws_iam_role.config_role.name
}

resource "aws_config_delivery_channel" "config_delivery_channel" {
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  sns_topic_arn  = aws_sns_topic.config_topic.arn
}

