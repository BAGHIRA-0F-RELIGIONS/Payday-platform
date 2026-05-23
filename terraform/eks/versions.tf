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

  # State stored in the same bucket Velero already uses.
  # The bucket already exists — run these two commands first, then terraform init -migrate-state:
  #
  #   aws s3api put-bucket-versioning \
  #     --bucket payday-cluster-velero-backups-207717182270 \
  #     --versioning-configuration Status=Enabled
  #
  #   aws dynamodb create-table \
  #     --table-name payday-terraform-lock \
  #     --attribute-definitions AttributeName=LockID,AttributeType=S \
  #     --key-schema AttributeName=LockID,KeyType=HASH \
  #     --billing-mode PAY_PER_REQUEST \
  #     --region us-east-1
  backend "s3" {
    bucket         = "payday-cluster-velero-backups-207717182270"
    key            = "terraform/eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "payday-terraform-lock"
    encrypt        = true
  }
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
