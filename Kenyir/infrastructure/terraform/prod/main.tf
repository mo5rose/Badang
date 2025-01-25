# main.tf
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  environment          = var.environment
}

module "eks" {
  source = "./modules/compute"
  
  cluster_name         = "datalake-${var.environment}"
  cluster_version      = var.eks_cluster_version
  vpc_id              = module.networking.vpc_id
  subnet_ids          = module.networking.private_subnet_ids
  node_groups         = var.node_groups
}

module "storage" {
  source = "./modules/storage"
  
  environment         = var.environment
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.private_subnet_ids
}

module "database" {
  source = "./modules/database"
  
  environment         = var.environment
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.private_subnet_ids
  availability_zones = var.availability_zones
}

module "monitoring" {
  source = "./modules/monitoring"
  
  cluster_name       = module.eks.cluster_name
  environment       = var.environment
}

module "security" {
  source = "./modules/security"
  
  vpc_id           = module.networking.vpc_id
  environment      = var.environment
}