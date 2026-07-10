module "vpc" {
  source = "./modules/vpc"
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr = var.vpc_cidr_block
  public_subnet_cidrs = var.public_cidr_block
  private_subnet_cidrs = var.private_cidr_block
  azs = var.azs
}

module "iam" {
  source = "./modules/iam"
  project_name = var.project_name
}

module "security" {
  source = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

module "eks" {
  source = "./modules/eks"
  project_name = var.project_name
  environment  = var.environment
  cluster_version = "1.30"
  node_instance_types = ["t3.medium"]
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 3
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids

  eks_cluster_role_arn = module.iam.eks_cluster_role_arn
  eks_node_role_arn    = module.iam.eks_node_role_arn
  eks_cluster_sg_id    = module.security.eks_cluster_sg_id

  depends_on = [module.iam, module.vpc, module.security]
}