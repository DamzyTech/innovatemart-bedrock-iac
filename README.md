# ALTSCHOOL CLOUD ENGINEERING MONTH 2 ASSESSMENT

## TASK: InnovateMart’s Inaugural EKS Deployment
  This README will explain in much details how I achieved this task. The sections are:
  1. Infrastructure setup using Terraform
  2. Application deployment
  3. Creating an IAM User with read-only access

## Prerequisites

Before starting, the following tools were installed and configured on my Windows machine:

- [AWS CLI](https://docs.aws.amazon.com/cli/)  
- [Terraform](https://developer.hashicorp.com/terraform/downloads)  
- [kubectl](https://kubernetes.io/docs/tasks/tools/)  
- [helm](https://helm.sh/docs/intro/install/)  
- [git](https://git-scm.com/downloads/) for version control
- [Github](https://github.com/) for CI/CD

- configured aws cli with 'aws configure' after creating a new IAM called InnovateMart with adminaccess.
## Repository Structure

This repository (innovatemart-bedrock-iac) contains:



bedrock-iac/
├─ terraform/
│  ├─ backend.tf            # S3 + DynamoDB backend (remote state)
│  ├─ providers.tf
│  ├─ vpc.tf
│  ├─ eks.tf
│  ├─ iam.tf
│  ├─ variables.tf
│  ├─ outputs.tf
├─ k8s-manifests/
│  ├─ retail-store/       
│  └─ dev-readonly-rbac.yaml
├─ .github/workflows/
│  ├─ terraform-plan.yml
│  └─ terraform-apply.yml
└─ README.md



## Step-by-Step Implementation

### Phase 1: Initialize the Git Repository

1. Create GitHub Repository:
Created a new repository on GitHub named innovatemart-bedrock-iac.
Cloned locally: git clone https://github.com/DamzyTech/innovatemart-bedrock-iac.git.
Purpose: Hosts Terraform IaC code and CI/CD pipeline. Uses GitFlow.

2. Set Up Terraform:
Navigated to the repo: cd innovatemart-bedrock-iac.
Initialized Terraform: terraform init.
Purpose: Prepares Terraform to manage infrastructure.

3. Configured s3 and DynamoDB in the backend.tf file:

- terraform {
  backend "s3" {
    bucket         = "bedrock-terraform-state-oyindamola-2025"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"   
    dynamodb_table = "bedrock-terraform-lock"
    encrypt        = true
  }

- Ran terraform init again.
- Purpose: Stores Terraform state remotely for consistency and team collaboration.
- Verification: Confirm bucket exists in AWS Console (S3) and terraform.tfstate appears after apply.

### Phase 2: Provision Infrastructure with Terraform

4. Next I defined the providers.tf and variables.tf files

   - terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.14.0"
    }
  }
}

provider "aws" {
  region = var.region # Configuration options
}

  - variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "bedrock-eks"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}


5. I provision vpc by creating the vpc.tf file:
  
  - module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "bedrock-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = true
}

6. I provision eks by creating the eks.tf file:

   - module "eks" {
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

7. I moved on to creating an output.tf file:


#### VPC Outputs

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "The IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "The IDs of the private subnets"
  value       = module.vpc.private_subnets
}

#### EKS Outputs
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL for the EKS cluster (needed for IRSA)"
  value       = module.eks.cluster_oidc_issuer_url
}


8. Apply Infrastructure:

   - Ran 'terraform init' to download all the neccessary modules
   - Ran 'terraform plan -out plan.tfplan' to preview changes and store in a 'plan.tfplan' to avoid unneccassry changes.
   - Ran 'terraform apply plan.tfplan' to create all resources on AWS. It took about 5-10 mins.
   - I logged in to the Console and confirmed all resources were created.
  <img width="956" height="406" alt="image" src="https://github.com/user-attachments/assets/fed48eff-5b1d-4e68-8aa6-a30653400cf9" />
  <img width="952" height="415" alt="image" src="https://github.com/user-attachments/assets/dfddac20-7473-4a70-9391-f94a94046fd4" />

9. Commit IaC Code:

- Committed: git add .; git commit -m "IaC for VPC and EKS"; git push origin main.
- Purpose: Stores IaC in GitHub for CI/CD integration.

### Phase 3: Deploy the Retail Store Application

1. Clone Application Repository:

- Cloned: git clone https://github.com/aws-containers/retail-store-sample-app.git.
- Navigated: cd retail-store-sample-app.
- Purpose: Obtains Kubernetes manifests for microservices and dependencies.

2. Deploy Dependencies and Services:

- Ensured kubectl was configured: aws eks update-kubeconfig --name innovatemart-eks --region us-east-1.
- Then I deploy all by running this; kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
- I checked the console and saw that all were succcessfully deployed.
<img width="957" height="461" alt="image" src="https://github.com/user-attachments/assets/d61764a6-df91-45d7-b95a-2760b7a1fe47" />
<img width="960" height="336" alt="image" src="https://github.com/user-attachments/assets/94e280b4-9072-4a45-b223-c454e37bd067" />
<img width="662" height="397" alt="image" src="https://github.com/user-attachments/assets/ef7807e6-5e70-46b6-af96-4e4883d565f8" />
<img width="955" height="442" alt="image" src="https://github.com/user-attachments/assets/10ec11d5-c53e-45d7-b051-837c5ca04988" />


