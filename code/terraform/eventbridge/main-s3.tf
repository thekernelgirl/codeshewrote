# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "event_bus_name" {
  description = "Name of the EventBridge event bus"
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket to trigger the event"
}

variable "s3_event_pattern" {
  description = "Event pattern for S3 events"
  default     = <<EOF
{
  "source": ["aws.s3"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["s3.amazonaws.com"],
    "eventName": ["PutObject"]
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "s3_event_rule" {
  name                = "s3-event-rule"
  event_pattern       = var.s3_event_pattern
  event_bus_name      = var.event_bus_name
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "s3_event_target" {
  rule             = aws_cloudwatch_event_rule.s3_event_rule.name
  target_id        = "s3-event-target"
  arn              = var.s3_bucket_arn
}

