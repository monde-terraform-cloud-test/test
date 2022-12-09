provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.39.0"
    }
  }
  cloud {
    organization = "edion-poc-org"
    hostname = "app.terraform.io"

    workspaces {
      name = "state-sample-remote"
    }
  }
}


