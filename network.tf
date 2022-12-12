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

# ---------------------------
# Subnet
# ---------------------------
resource "aws_subnet" "terraform_public_1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.2.0/25"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "terraform-public-1a"
  }
}

# ---------------------------
# EC2
# ---------------------------

# EC2作成
resource "aws_instance" "terraform_ec2"{
  ami                         = "ami-072bfb8ae2c884cc4"
  instance_type               = "t2.micro"
  availability_zone           = "ap-northeast-1a"
  vpc_security_group_ids      = ["sg-0a71e946535eb00dc"]
  subnet_id                   = aws_subnet.terraform_public_1a.id
  associate_public_ip_address = "true"
  key_name                    = "ansible-controller"
  tags = {
    Name = "terraform-ec2"
  }
}
