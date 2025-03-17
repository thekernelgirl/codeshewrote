require 'aws-sdk-ec2'

# AWS credentials
Aws.config.update({
  region: 'your_region',
  credentials: Aws::Credentials.new('your_access_key_id', 'your_secret_access_key')
})

# Create EC2 client
ec2 = Aws::EC2::Client.new

# Launch EC2 instance
resp = ec2.run_instances({
  image_id: 'your_ami_id', # Specify the AMI ID for the desired Quake 2 server image
  instance_type: 'your_instance_type', # Specify the instance type (e.g., t2.micro)
  key_name: 'your_key_pair_name', # Specify the key pair name for SSH access
  security_group_ids: ['your_security_group_id'], # Specify the security group ID for the instance
  user_data: "#!/bin/bash\nsudo apt-get update -y && sudo apt-get install -y quake2-server", # Install Quake 2 server on startup
  min_count: 1,
  max_count: 1
})

# Retrieve the instance ID
instance_id = resp.instances[0].instance_id

# Wait until instance is running
ec2.wait_until(:instance_running, instance_ids:[instance_id])

puts "Instance #{instance_id} is now running."

# Print instance details
resp = ec2.describe_instances({
  instance_ids: [instance_id]
})

instance = resp.reservations[0].instances[0]

puts "Public IP Address: #{instance.public_ip_address}"
puts "Public DNS Name: #{instance.public_dns_name}"

