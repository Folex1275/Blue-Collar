terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state — configure bucket/key before first apply
  backend "s3" {
    bucket         = "bluecollar-terraform-state"
    key            = "bluecollar/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "bluecollar-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "BlueCollar"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ---------------------------------------------------------------------------
# Modules
# ---------------------------------------------------------------------------

module "networking" {
  source      = "./modules/networking"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

module "database" {
  source            = "./modules/database"
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
}

module "registry" {
  source      = "./modules/registry"
  environment = var.environment
}

module "cdn" {
  source                  = "./modules/cdn"
  environment             = var.environment
  assets_bucket_name      = var.assets_bucket_name
  use_default_certificate = var.use_default_certificate
  acm_certificate_arn     = var.acm_certificate_arn
}
