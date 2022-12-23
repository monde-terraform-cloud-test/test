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
# Security Group
# ---------------------------
# 自分のパブリックIP取得
#data "http" "ifconfig" {
#  url = "http://ipv4.icanhazip.com/"
#}

#variable "allowed_cidr" {
#  default = null
#}

#locals {
#  myip          = chomp(data.http.ifconfig.body)
#  allowed_cidr  = (var.allowed_cidr == null) ? "${local.myip}/32" : var.allowed_cidr
#}

# Security Group作成
#resource "aws_security_group" "terraform_ec2_sg" {
#  name              = "terraform-ec2-sg"
#  description       = "For EC2 Linux"
#  vpc_id            = aws_vpc.vpc.id
#  tags = {
#    Name = "terraform-ec2-sg"
#  }

#  # インバウンドルール
#  ingress {
#    from_port   = 22
#    to_port     = 22
#    protocol    = "tcp"
#    cidr_blocks = [local.allowed_cidr]
#  }

#  # アウトバウンドルール
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}

# ---------------------------
# EC2
# ---------------------------

# EC2作成
#resource "aws_instance" "terraform_ec2"{
#  ami                         = "ami-072bfb8ae2c884cc4"
#  instance_type               = "t2.micro"
#  availability_zone           = "ap-northeast-1a"
#  vpc_security_group_ids      = [aws_security_group.terraform_ec2_sg.id]
#  subnet_id                   = "subnet-0da8455aa2c26be8e"
#  key_name                    = "ansible-controller"
#  tags = {
#    Name = "terraform-ec2"
#  }
#}
