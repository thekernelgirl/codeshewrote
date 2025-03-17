# main.tf

variable "database_name" {
  description = "Name of the Athena database"
  type        = string
}

variable "table_name" {
  description = "Name of the table to create"
  type        = string
}

variable "s3_bucket" {
  description = "Name of the S3 bucket where data is stored"
  type        = string
}

variable "s3_prefix" {
  description = "Prefix of the S3 location where data is stored"
  type        = string
}

variable "column_definitions" {
  description = "List of column definitions for the Athena table"
  type        = list(object({
    name = string
    type = string
  }))
}

resource "aws_glue_catalog_database" "athena_database" {
  name = var.database_name
}

resource "aws_glue_catalog_table" "athena_table" {
  database_name = aws_glue_catalog_database.athena_database.name
  name          = var.table_name
  table_type    = "EXTERNAL_TABLE"
  
  parameters = {
    "classification" = "csv"
    "compressionType" = "none"
    "typeOfData" = "file"
  }

  storage_descriptor {
    location      = "s3://${var.s3_bucket}/${var.s3_prefix}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    serde_info {
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
      parameters = {
        "separatorChar" = ","
      }
    }
    columns = [
      for col in var.column_definitions :
      {
        name = col.name
        type = col.type
      }
    ]
  }
}

