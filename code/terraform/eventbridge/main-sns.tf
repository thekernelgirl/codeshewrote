# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "event_bus_name" {
  description = "Name of the EventBridge event bus"
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic"
}

variable "sns_event_pattern" {
  description = "Event pattern for SNS events"
  default     = <<EOF
{
  "source": ["aws.sns"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["sns.amazonaws.com"],
    "eventName": ["Publish"]
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "sns_event_rule" {
  name                = "sns-event-rule"
  event_pattern       = var.sns_event_pattern
  event_bus_name      = var.event_bus_name
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "sns_event_target" {
  rule             = aws_cloudwatch_event_rule.sns_event_rule.name
  target_id        = "sns-event-target"
  arn              = var.sns_topic_arn
}

