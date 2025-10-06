# This is my structure, we would have to situate this differently in another repo
module "networking" {
  source = "../../terraform/SQLServ"
  
  vpc_cidr = var.vpc_cidr
  region   = var.region
}
#This is my structure, we would have to situate this differently in another repo
module "compute" {
  source = "../../terraform/IIS"
  
  instance_count = var.instance_count
  instance_type  = var.instance_type
  vpc_id         = module.networking.vpc_id
}
