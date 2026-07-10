terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state - production must NOT use local state.
  # Create the S3 bucket + DynamoDB lock table once, out-of-band, then uncomment:
  #
  # backend "s3" {
  #   bucket         = "ai-microservice-tfstate-<unique-suffix>"
  #   key            = "eks/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

# tls provider needed for OIDC thumbprint lookup
