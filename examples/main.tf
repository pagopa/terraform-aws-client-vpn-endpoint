terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}


data "aws_secretsmanager_secret" "saml" {
  name = "vpn_sso"
}

data "aws_secretsmanager_secret_version" "saml" {
  secret_id     = data.aws_secretsmanager_secret.saml.id
  version_stage = "AWSCURRENT"
}

resource "aws_iam_saml_provider" "vpn" {
  name                   = "VPN_SSO"
  saml_metadata_document = base64decode(jsondecode(data.aws_secretsmanager_secret_version.saml.secret_string)["saml_metadata_xml"]) # saml_metadata_xml
}

module "vpc" {
  source                = "terraform-aws-modules/vpc/aws"
  version               = "6.7.2"
  name                  = "myvpc"
  cidr                  = "10.0.0.0/16"
  azs                   = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_suffix = "private"
  public_subnets        = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  public_subnet_suffix  = "public"
  enable_nat_gateway    = false

  enable_dns_hostnames = true
  enable_dns_support   = true

}


module "vpn" {
  source                     = "../"
  endpoint_name              = "vpn"
  endpoint_client_cidr_block = "10.100.0.0/22"
  endpoint_subnets           = [module.vpc.private_subnets[0]] # Attach VPN to single subnet. Reduce cost
  endpoint_vpc_id            = module.vpc.vpc_id
  tls_subject_common_name    = "vpn.sandbox.pagopa.it"
  saml_provider_arn          = aws_iam_saml_provider.vpn.arn

  authorization_rules = {}

  authorization_rules_all_groups = {
    full_access_private_subnet_0 = module.vpc.private_subnets_cidr_blocks[0]
  }


  depends_on = [
    module.vpc
  ]

}