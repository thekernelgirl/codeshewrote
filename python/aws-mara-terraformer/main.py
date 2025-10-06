#!/usr/bin/env python3
"""
AWS Resource to Terraform Configuration Generator
Converts existing AWS resources into Terraform IaC files
"""

import boto3
import json
import argparse
import sys
from pathlib import Path


class TerraformGenerator:
    def __init__(self, region='us-east-1'):
        self.region = region
        self.ec2 = boto3.client('ec2', region_name=region)
        self.rds = boto3.client('rds', region_name=region)
        self.s3 = boto3.client('s3', region_name=region)
        self.elb = boto3.client('elbv2', region_name=region)
        
    def identify_resource_type(self, resource_id):
        """Determine AWS resource type from ID pattern"""
        prefix_map = {
            'i-': 'ec2_instance',
            'vpc-': 'vpc',
            'subnet-': 'subnet',
            'sg-': 'security_group',
            'igw-': 'internet_gateway',
            'nat-': 'nat_gateway',
            'rtb-': 'route_table',
            'vol-': 'ebs_volume',
            'ami-': 'ami',
            'arn:aws:rds': 'rds_instance',
            'arn:aws:s3': 's3_bucket',
        }
        
        for prefix, resource_type in prefix_map.items():
            if resource_id.startswith(prefix):
                return resource_type
        
        # Check if it's an S3 bucket name (no prefix)
        if not resource_id.startswith(('i-', 'vpc-', 'subnet-', 'sg-', 'arn:')):
            try:
                self.s3.head_bucket(Bucket=resource_id)
                return 's3_bucket'
            except:
                pass
                
        return None
    
    def get_ec2_instance(self, instance_id):
        """Retrieve EC2 instance details"""
        response = self.ec2.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]
        
        tags = {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
        
        return {
            'ami': instance['ImageId'],
            'instance_type': instance['InstanceType'],
            'subnet_id': instance.get('SubnetId', ''),
            'vpc_security_group_ids': [sg['GroupId'] for sg in instance.get('SecurityGroups', [])],
            'key_name': instance.get('KeyName', ''),
            'availability_zone': instance['Placement']['AvailabilityZone'],
            'private_ip': instance.get('PrivateIpAddress', ''),
            'tags': tags,
            'root_block_device': {
                'volume_size': instance['BlockDeviceMappings'][0]['Ebs']['VolumeSize'] if instance.get('BlockDeviceMappings') else 8,
                'volume_type': 'gp3',
            },
            'associate_public_ip_address': instance.get('PublicIpAddress') is not None,
        }
    
    def get_security_group(self, sg_id):
        """Retrieve Security Group details"""
        response = self.ec2.describe_security_groups(GroupIds=[sg_id])
        sg = response['SecurityGroups'][0]
        
        return {
            'name': sg['GroupName'],
            'description': sg['Description'],
            'vpc_id': sg['VpcId'],
            'ingress': sg.get('IpPermissions', []),
            'egress': sg.get('IpPermissionsEgress', []),
            'tags': {tag['Key']: tag['Value'] for tag in sg.get('Tags', [])}
        }
    
    def get_s3_bucket(self, bucket_name):
        """Retrieve S3 bucket configuration"""
        try:
            versioning = self.s3.get_bucket_versioning(Bucket=bucket_name)
            encryption = self.s3.get_bucket_encryption(Bucket=bucket_name)
            
            return {
                'bucket_name': bucket_name,
                'versioning_enabled': versioning.get('Status') == 'Enabled',
                'encryption_enabled': 'Rules' in encryption,
            }
        except Exception as e:
            return {
                'bucket_name': bucket_name,
                'versioning_enabled': False,
                'encryption_enabled': False,
            }
    
    def get_vpc(self, vpc_id):
        """Retrieve VPC details"""
        response = self.ec2.describe_vpcs(VpcIds=[vpc_id])
        vpc = response['Vpcs'][0]
        
        return {
            'cidr_block': vpc['CidrBlock'],
            'enable_dns_hostnames': vpc.get('EnableDnsHostnames', True),
            'enable_dns_support': vpc.get('EnableDnsSupport', True),
            'tags': {tag['Key']: tag['Value'] for tag in vpc.get('Tags', [])}
        }
    
    def generate_ec2_terraform(self, resource_id, data):
        """Generate Terraform files for EC2 instance"""
        resource_name = data['tags'].get('Name', resource_id).replace(' ', '_').replace('-', '_').lower()
        
        main_tf = f'''# EC2 Instance Configuration
resource "aws_instance" "{resource_name}" {{
  ami                         = var.ami_id
  instance_type              = var.instance_type
  subnet_id                  = var.subnet_id
  vpc_security_group_ids     = var.security_group_ids
  key_name                   = var.key_name
  associate_public_ip_address = var.associate_public_ip

  root_block_device {{
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }}

  tags = {{
    Name        = var.instance_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }}
}}
'''
        
        variables_tf = f'''variable "region" {{
  description = "AWS region"
  type        = string
  default     = "{self.region}"
}}

variable "ami_id" {{
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "{data['ami']}"
}}

variable "instance_type" {{
  description = "EC2 instance type"
  type        = string
  default     = "{data['instance_type']}"
}}

variable "subnet_id" {{
  description = "Subnet ID for the instance"
  type        = string
  default     = "{data['subnet_id']}"
}}

variable "security_group_ids" {{
  description = "List of security group IDs"
  type        = list(string)
  default     = {json.dumps(data['vpc_security_group_ids'])}
}}

variable "key_name" {{
  description = "SSH key pair name"
  type        = string
  default     = "{data['key_name']}"
}}

variable "associate_public_ip" {{
  description = "Associate a public IP address"
  type        = bool
  default     = {str(data['associate_public_ip_address']).lower()}
}}

variable "root_volume_size" {{
  description = "Size of root volume in GB"
  type        = number
  default     = {data['root_block_device']['volume_size']}
}}

variable "root_volume_type" {{
  description = "Type of root volume"
  type        = string
  default     = "{data['root_block_device']['volume_type']}"
}}

variable "instance_name" {{
  description = "Name tag for the instance"
  type        = string
  default     = "{data['tags'].get('Name', resource_id)}"
}}

variable "environment" {{
  description = "Environment tag"
  type        = string
  default     = "{data['tags'].get('Environment', 'production')}"
}}
'''
        
        outputs_tf = f'''output "instance_id" {{
  description = "ID of the EC2 instance"
  value       = aws_instance.{resource_name}.id
}}

output "instance_public_ip" {{
  description = "Public IP address of the instance"
  value       = aws_instance.{resource_name}.public_ip
}}

output "instance_private_ip" {{
  description = "Private IP address of the instance"
  value       = aws_instance.{resource_name}.private_ip
}}

output "instance_arn" {{
  description = "ARN of the EC2 instance"
  value       = aws_instance.{resource_name}.arn
}}
'''
        
        return main_tf, variables_tf, outputs_tf
    
    def generate_s3_terraform(self, resource_id, data):
        """Generate Terraform files for S3 bucket"""
        bucket_name = data['bucket_name'].replace('.', '_').replace('-', '_')
        
        main_tf = f'''# S3 Bucket Configuration
resource "aws_s3_bucket" "{bucket_name}" {{
  bucket = var.bucket_name

  tags = {{
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }}
}}

resource "aws_s3_bucket_versioning" "{bucket_name}_versioning" {{
  bucket = aws_s3_bucket.{bucket_name}.id

  versioning_configuration {{
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }}
}}

resource "aws_s3_bucket_server_side_encryption_configuration" "{bucket_name}_encryption" {{
  bucket = aws_s3_bucket.{bucket_name}.id

  rule {{
    apply_server_side_encryption_by_default {{
      sse_algorithm = "AES256"
    }}
  }}
}}
'''
        
        variables_tf = f'''variable "region" {{
  description = "AWS region"
  type        = string
  default     = "{self.region}"
}}

variable "bucket_name" {{
  description = "Name of the S3 bucket"
  type        = string
  default     = "{data['bucket_name']}"
}}

variable "versioning_enabled" {{
  description = "Enable bucket versioning"
  type        = bool
  default     = {str(data['versioning_enabled']).lower()}
}}

variable "environment" {{
  description = "Environment tag"
  type        = string
  default     = "production"
}}
'''
        
        outputs_tf = f'''output "bucket_id" {{
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.{bucket_name}.id
}}

output "bucket_arn" {{
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.{bucket_name}.arn
}}

output "bucket_domain_name" {{
  description = "Domain name of the bucket"
  value       = aws_s3_bucket.{bucket_name}.bucket_domain_name
}}
'''
        
        return main_tf, variables_tf, outputs_tf
    
    def generate_security_group_terraform(self, resource_id, data):
        """Generate Terraform files for Security Group"""
        sg_name = data['name'].replace(' ', '_').replace('-', '_').lower()
        
        ingress_rules = []
        for rule in data['ingress']:
            from_port = rule.get('FromPort', 0)
            to_port = rule.get('ToPort', 0)
            protocol = rule.get('IpProtocol', '-1')
            cidr_blocks = [ip_range['CidrIp'] for ip_range in rule.get('IpRanges', [])]
            
            if cidr_blocks:
                ingress_rules.append(f'''  ingress {{
    from_port   = {from_port}
    to_port     = {to_port}
    protocol    = "{protocol}"
    cidr_blocks = {json.dumps(cidr_blocks)}
  }}''')
        
        main_tf = f'''# Security Group Configuration
resource "aws_security_group" "{sg_name}" {{
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id

{chr(10).join(ingress_rules)}

  egress {{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }}

  tags = {{
    Name        = var.security_group_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }}
}}
'''
        
        variables_tf = f'''variable "region" {{
  description = "AWS region"
  type        = string
  default     = "{self.region}"
}}

variable "security_group_name" {{
  description = "Name of the security group"
  type        = string
  default     = "{data['name']}"
}}

variable "security_group_description" {{
  description = "Description of the security group"
  type        = string
  default     = "{data['description']}"
}}

variable "vpc_id" {{
  description = "VPC ID"
  type        = string
  default     = "{data['vpc_id']}"
}}

variable "environment" {{
  description = "Environment tag"
  type        = string
  default     = "production"
}}
'''
        
        outputs_tf = f'''output "security_group_id" {{
  description = "ID of the security group"
  value       = aws_security_group.{sg_name}.id
}}

output "security_group_arn" {{
  description = "ARN of the security group"
  value       = aws_security_group.{sg_name}.arn
}}
'''
        
        return main_tf, variables_tf, outputs_tf
    
    def generate(self, resource_id, output_dir='.'):
        """Main generation function"""
        resource_type = self.identify_resource_type(resource_id)
        
        if not resource_type:
            print(f"Error: Could not identify resource type for {resource_id}")
            return False
        
        print(f"Detected resource type: {resource_type}")
        print(f"Fetching resource details...")
        
        try:
            if resource_type == 'ec2_instance':
                data = self.get_ec2_instance(resource_id)
                main_tf, variables_tf, outputs_tf = self.generate_ec2_terraform(resource_id, data)
            elif resource_type == 's3_bucket':
                data = self.get_s3_bucket(resource_id)
                main_tf, variables_tf, outputs_tf = self.generate_s3_terraform(resource_id, data)
            elif resource_type == 'security_group':
                data = self.get_security_group(resource_id)
                main_tf, variables_tf, outputs_tf = self.generate_security_group_terraform(resource_id, data)
            else:
                print(f"Error: Resource type {resource_type} not yet supported")
                return False
            
            # Write files
            output_path = Path(output_dir)
            output_path.mkdir(exist_ok=True)
            
            (output_path / 'main.tf').write_text(main_tf)
            (output_path / 'variables.tf').write_text(variables_tf)
            (output_path / 'outputs.tf').write_text(outputs_tf)
            
            print(f"\n✓ Successfully generated Terraform files in {output_dir}/")
            print(f"  - main.tf")
            print(f"  - variables.tf")
            print(f"  - outputs.tf")
            
            return True
            
        except Exception as e:
            print(f"Error: {str(e)}")
            return False


def main():
    parser = argparse.ArgumentParser(
        description='Generate Terraform configuration from existing AWS resources'
    )
    parser.add_argument('resource_id', help='AWS resource ID (e.g., i-1234567890abcdef0)')
    parser.add_argument('--region', default='us-east-1', help='AWS region (default: us-east-1)')
    parser.add_argument('--output', '-o', default='.', help='Output directory (default: current directory)')
    
    args = parser.parse_args()
    
    generator = TerraformGenerator(region=args.region)
    success = generator.generate(args.resource_id, args.output)
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
