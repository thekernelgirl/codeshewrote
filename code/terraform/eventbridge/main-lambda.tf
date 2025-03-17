# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "event_bus_name" {
  description = "Name of the EventBridge event bus"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to trigger"
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function"
}

variable "lambda_event_pattern" {
  description = "Event pattern for Lambda events"
  default     = <<EOF
{
  "source": ["aws.lambda"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["lambda.amazonaws.com"],
    "eventName": ["Invoke"]
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "lambda_event_rule" {
  name                = "lambda-event-rule"
  event_pattern       = var.lambda_event_pattern
  event_bus_name      = var.event_bus_name
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule             = aws_cloudwatch_event_rule.lambda_event_rule.name
  target_id        = "lambda-event-target"
  arn              = var.lambda_function_arn
}

