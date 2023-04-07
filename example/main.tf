provider "aws" {

  region = "eu-west-1"
}

locals {
  common_tags ={
    environment="staging"
    BusinessUnit="test"
  }
}

module "my-vpc" {
  source      = "../"
  vpc-cidr    = "192.168.0.0/21"
  vpc-enabled = true
  vpc-public-subnet-cidr = ["192.168.0.0/26", "192.168.0.64/26"]
  vpc-private-subnet-cidr = ["192.168.1.0/26", "192.168.1.64/26"]
  vpc-k8s-subnet-cidr = ["192.168.2.0/24", "192.168.3.0/24"]
  vpc-db-subnet-cidr = ["192.168.4.0/27", "192.168.4.32/27"]
  common_tags = local.common_tags
  prefix = "ifx-stage"
}

