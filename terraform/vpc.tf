module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "bedrock-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = true
}
