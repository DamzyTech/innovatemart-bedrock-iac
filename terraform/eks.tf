module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name    = var.cluster_name
  kubernetes_version = "1.33"
  
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id  = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

 tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
