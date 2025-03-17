# main.tf

provider "aws" {
  region = "us-east-1"  # Choose your desired region
}

# Create a VPC, subnets, security groups, etc.
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  # Add more VPC configurations as needed
}

# Create an EC2 instance
resource "aws_instance" "awx_instance" {
  ami                    = "ami-xxxxxxxxxx"  # Use an appropriate AMI ID
  instance_type          = "t2.micro"        # Choose an appropriate instance type
  vpc_security_group_ids = [aws_security_group.awx.id]
  subnet_id              = aws_subnet.awx.id
  # Add more instance configurations as needed

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      # Install necessary dependencies for AWX
      "sudo yum install -y epel-release",
      "sudo yum install -y git python3-pip python3-devel gcc nodejs npm"
    ]
  }
}

# Create a security group for AWX
resource "aws_security_group" "awx" {
  vpc_id = aws_vpc.my_vpc.id
  # Configure security group rules for AWX
}

# Create a subnet for the EC2 instance
resource "aws_subnet" "awx" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"  # Choose an appropriate CIDR block
  availability_zone = "us-east-1a"   # Choose an appropriate availability zone
  # Add more subnet configurations as needed
}

