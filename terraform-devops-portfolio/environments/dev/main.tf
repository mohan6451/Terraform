terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tfstate-portfolio-mohan"   # from bootstrap output
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Environment = var.env
    Project     = "devops-portfolio"
    ManagedBy   = "terraform"
  }
}

# ------------------------------------------------------------------
# Modules
# ------------------------------------------------------------------
module "vpc" {
  source     = "../../modules/vpc"
  env        = var.env
  aws_region = var.aws_region
  vpc_cidr   = var.vpc_cidr
  tags       = local.common_tags
}

module "iam" {
  source      = "../../modules/iam"
  env         = var.env
  github_org  = var.github_org
  github_repo = var.github_repo
  tags        = local.common_tags
}

module "security_groups" {
  source            = "../../modules/security-groups"
  env               = var.env
  vpc_id            = module.vpc.vpc_id
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  tags              = local.common_tags
}

module "ec2" {
  source                = "../../modules/ec2"
  env                   = var.env
  aws_region            = var.aws_region
  instance_type         = var.instance_type
  worker_count          = var.worker_count
  public_subnet_ids     = module.vpc.public_subnet_ids
  master_sg_id          = module.security_groups.master_sg_id
  worker_sg_id          = module.security_groups.worker_sg_id
  instance_profile_name = module.iam.instance_profile_name
  public_key_path       = var.public_key_path
  tags                  = local.common_tags
}
