module "athena_table" {
  source = "./path/to/module"
  
  database_name       = "my_database"
  table_name          = "my_table"
  s3_bucket           = "my-s3-bucket"
  s3_prefix           = "data/"
  column_definitions = [
    {
      name = "column1"
      type = "string"
    },
    {
      name = "column2"
      type = "int"
    },
    # Add more column definitions as needed
  ]
}

