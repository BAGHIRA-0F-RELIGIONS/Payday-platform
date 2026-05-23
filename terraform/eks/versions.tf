# Terraform version and provider requirements
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }

  # Store Terraform state in S3 so your team shares the same state.
  # Create the bucket first:
  #   aws s3 mb s3://YOUR_BUCKET_NAME --region us-east-1
  # Then uncomment this block:
  # backend "s3" {
  #   bucket         = "YOUR_BUCKET_NAME-terraform-state"
  #   key            = "payday/eks/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "payday-terraform-lock"   # For state locking
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "payday-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Kubernetes provider — configured after EKS is created
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}
