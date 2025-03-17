# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

resource "aws_securityhub_account" "main" {
  # Enable Security Hub for the AWS account
}

