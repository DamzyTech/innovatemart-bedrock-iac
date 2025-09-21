# AWS region to deploy resources
region = "us-east-1"

# EKS cluster name
cluster_name = "bedrock-eks"

# VPC CIDR block
vpc_cidr = "10.0.0.0/16"

# Public subnets
public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

# Private subnets
private_subnets = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

# Your AWS account ID
account_id = "431522527593"
