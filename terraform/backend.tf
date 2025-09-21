terraform {
  backend "s3" {
    bucket         = "bedrock-terraform-state-oyindamola-2025"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"   
    dynamodb_table = "bedrock-terraform-lock"
    encrypt        = true
  }
}
