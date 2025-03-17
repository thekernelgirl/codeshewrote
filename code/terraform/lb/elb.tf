# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "elb_name" {
  description = "Name of the Elastic Load Balancer"
}

variable "listener_port" {
  description = "Port on which the load balancer will listen for incoming traffic"
  default     = 80  # Update with your desired listener port
}

variable "target_port" {
  description = "Port on which the load balancer will forward traffic to the targets"
  default     = 80  # Update with your desired target port
}

variable "subnet_ids" {
  description = "List of subnet IDs where the load balancer will be provisioned"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs for the load balancer"
  type        = list(string)
}

resource "aws_lb" "elb" {
  name               = var.elb_name
  internal           = false  # Set to true if the load balancer is internal
  load_balancer_type = "application"  # Set to "network" for Network Load Balancer

  subnet_ids         = var.subnet_ids
  security_groups    = var.security_groups

  tags = {
    Name = var.elb_name
  }
}

resource "aws_lb_listener" "elb_listener" {
  load_balancer_arn = aws_lb.elb.arn
  port              = var.listener_port
  protocol          = "HTTP"  # Update with your desired listener protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elb_target_group.arn
  }
}

resource "aws_lb_target_group" "elb_target_group" {
  name        = "${var.elb_name}-target-group"
  port        = var.target_port
  protocol    = "HTTP"  # Update with your desired target protocol
  target_type = "instance"  # Update with "ip" if using Network Load Balancer

  health_check {
    path                = "/"
    port                = var.target_port
    protocol            = "HTTP"  # Update with your desired health check protocol
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

