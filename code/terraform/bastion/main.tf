# main.tf

variable "vpc_id" {
  description = "ID of the VPC"
}

variable "subnet_id" {
  description = "ID of the public subnet where the bastion host will be deployed"
}

variable "instance_type" {
  description = "Instance type for the bastion host"
  default     = "t2.micro"
}

variable "ami" {
  description = "AMI ID for the bastion host"
  default     = "ami-xxxxxxxxxxxxxxxxx"  # Specify an appropriate AMI ID
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair for connecting to the bastion host"
}

variable "allowed_cidr_blocks" {
  description = "List of allowed CIDR blocks for SSH access to the bastion host"
  type        = list(string)
}

resource "aws_instance" "bastion_host" {
  ami             = var.ami
  instance_type   = var.instance_type
  subnet_id       = var.subnet_id
  key_name        = var.ssh_key_name

  # Allow SSH access only from specified CIDR blocks
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  tags = {
    Name = "BastionHost"
  }
}

