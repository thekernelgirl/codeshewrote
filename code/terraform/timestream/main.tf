# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

# Create Timestream database
resource "aws_timestream_database" "example" {
  name = "example_database"
}

# Create retention policy
resource "aws_timestream_table" "example_table" {
  name              = "example_table"
  database_name     = aws_timestream_database.example.name
  retention_period  = 30  # Retention period in days
}

# Create KMS key for encryption
resource "aws_kms_key" "timestream_key" {
  description             = "Timestream encryption key"
  deletion_window_in_days = 10
}

# Create Timestream user
resource "aws_timestream_user" "example_user" {
  user_name         = "example_user"
  access_level      = "READ_WRITE"  # Adjust access level as needed
  database_name     = aws_timestream_database.example.name
}

# Associate KMS key with Timestream
resource "aws_timestream_database_kms_key" "example_kms_key" {
  database_name = aws_timestream_database.example.name
  kms_key_id    = aws_kms_key.timestream_key.key_id
}

