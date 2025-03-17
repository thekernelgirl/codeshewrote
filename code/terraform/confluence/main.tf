# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

resource "aws_s3_bucket" "confluence_export_bucket" {
  bucket = "confluence-export-bucket"
  acl    = "private"
}

resource "null_resource" "export_confluence_data" {
  triggers = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Use the Confluence REST API to trigger an export
      # Example command:
      # curl -u username:password -X POST -H 'Content-Type: application/json' -d '{"exportType":"xml"}' https://your-confluence-url/rest/obm/1.0/runbackup
    EOT
  }

  provisioner "local-exec" {
    # Assuming the export file is generated in a directory named 'export'
    command = "aws s3 cp export/ s3://${aws_s3_bucket.confluence_export_bucket.bucket}/ --recursive"
  }
}

