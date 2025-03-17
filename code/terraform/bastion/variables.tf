# bastion.tf

module "bastion_host" {
  source = "./path/to/module"
  
  vpc_id             = "your_vpc_id"
  subnet_id          = "your_public_subnet_id"
  ssh_key_name       = "your_ssh_key_name"
  allowed_cidr_blocks = ["your_public_ip/32"]  # Example: ["123.123.123.123/32"]
}

