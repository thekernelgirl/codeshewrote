# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "grafana-cluster"
}

resource "aws_ecs_task_definition" "grafana_task_definition" {
  family                   = "grafana-task"
  container_definitions    = jsonencode([
    {
      name            = "grafana-container"
      image           = "grafana/grafana:latest"  # Specify the desired Grafana image
      portMappings    = [{
        containerPort = 3000
        hostPort      = 3000
      }]
      memory          = 512
      cpu             = 256
    }
  ])
}

resource "aws_ecs_service" "grafana_service" {
  name            = "grafana-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.grafana_task_definition.arn
  desired_count   = 1

  network_configuration {
    subnets = ["subnet-12345678"]  # Specify the subnets where your ECS tasks will run
    security_groups = ["sg-12345678"]  # Specify the security groups for your ECS tasks
    assign_public_ip = true
  }
}

