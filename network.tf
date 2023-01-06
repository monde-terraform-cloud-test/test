# ---------------------------
# VPC
# ---------------------------
resource "aws_vpc" "vpc" {
  cidr_block       = "192.168.2.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "terraform-test-vpc"
  }
}

