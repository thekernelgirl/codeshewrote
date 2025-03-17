# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "glue_job_name" {
  description = "Name of the Glue job"
}

variable "glue_script_location" {
  description = "S3 path to the script for the Glue job"
}

variable "glue_role_arn" {
  description = "ARN of the IAM role for the Glue job"
}

variable "glue_temp_dir" {
  description = "S3 path for temporary files used by the Glue job"
}

resource "aws_glue_job" "glue_job" {
  name          = var.glue_job_name
  role_arn      = var.glue_role_arn
  command {
    name        = "glueetl"
    script_location = var.glue_script_location
  }
  default_arguments = {
    "--TempDir" = var.glue_temp_dir
  }
}

