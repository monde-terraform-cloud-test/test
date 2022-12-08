# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${local.resource_prefix}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.resource_prefix}-igw"
  }
}

# Nat Gateway
resource "aws_nat_gateway" "nat" {
  # for_each = local.availability_zones
  for_each = {
    0 = "${data.aws_region.current.name}a" # 検証、開発は単一系統で配置
    # 1 = "${data.aws_region.current.name}c"
    # 2 = "${data.aws_region.current.name}d"
  }
  subnet_id     = data.aws_subnet.public[each.key].id
  allocation_id = aws_eip.nat_eip[each.key].id
  tags = {
    Name = "${local.resource_prefix}-nat-${substr(each.value, 13, 2)}"
  }
}
# Nat EIP
resource "aws_eip" "nat_eip" {
  vpc      = true
  # for_each = local.availability_zones
  for_each = {
    0 = "${data.aws_region.current.name}a" # 検証、開発は単一系統で配置
    # 1 = "${data.aws_region.current.name}c"
    # 2 = "${data.aws_region.current.name}d"
  }
  tags = {
    Name = "${local.resource_prefix}-nat-eip-${substr(each.value, 13, 2)}"
  }
}

# Subnet
resource "aws_subnet" "public" {
  for_each                = local.availability_zones
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = each.value
  cidr_block              = cidrsubnet(local.vpc_cidr, 4, each.key)
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${local.resource_prefix}-public-${substr(each.value, 13, 2)}"
  }
}

resource "aws_subnet" "private" {
  for_each                = local.availability_zones
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = each.value
  cidr_block              = cidrsubnet(local.vpc_cidr, 2, each.key + 1)
  map_public_ip_on_launch = "false"

  tags = {
    Name = "${local.resource_prefix}-private-${substr(each.value, 13, 2)}"
  }
}
