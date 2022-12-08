provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Environment = local.env
    }
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

terraform {
  backend "remote" {
    organization = "andgate-edion-ecsite"

    workspaces {
      name = "edion-ecsite-terraform-stg-frontend"
    }
  }
}
