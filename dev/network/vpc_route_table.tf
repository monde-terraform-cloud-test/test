# Route Table
## public
resource "aws_route_table" "public_route_igw_table" {
  for_each = local.availability_zones
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.resource_prefix}-public-${substr(each.value, 13, 2)}-rt"
  }
}
resource "aws_route" "public_route" {
  for_each               = local.availability_zones
  route_table_id         = aws_route_table.public_route_igw_table[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public_route_igw" {
  for_each       = local.availability_zones
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public_route_igw_table[each.key].id
}

## private
resource "aws_route_table" "private_route_nat_table" {
  #for_each = local.availability_zones
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name = "${local.resource_prefix}-private-rt"
  }
}
resource "aws_route" "private_route" {
  #for_each               = local.availability_zones
  route_table_id         = aws_route_table.private_route_nat_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id # 検証、開発は単一系統で配置
  # nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

/* transit gateway経由の接続 */
resource "aws_route" "private_route_to_system_cloud" {
  #for_each               = local.availability_zones
  route_table_id         = aws_route_table.private_route_nat_table.id
  destination_cidr_block = local.edion_system_cloud_cidr
  transit_gateway_id     = var.transit_gateway.system_cloud_gateway_id
}
resource "aws_route" "private_route_to_on_premise_01" {
  #for_each               = local.availability_zones
  route_table_id         = aws_route_table.private_route_nat_table.id
  destination_cidr_block = local.edion_on_premise_01_cidr
  transit_gateway_id     = var.transit_gateway.system_cloud_gateway_id
}
resource "aws_route" "private_route_to_on_premise_02" {
  #for_each               = local.availability_zones
  route_table_id         = aws_route_table.private_route_nat_table.id
  destination_cidr_block = local.edion_on_premise_02_cidr
  transit_gateway_id     = var.transit_gateway.system_cloud_gateway_id
}
resource "aws_route" "private_route_to_on_premise_03" {
  #for_each               = local.availability_zones
  route_table_id         = aws_route_table.private_route_nat_table.id
  destination_cidr_block = local.edion_on_premise_03_cidr
  transit_gateway_id     = var.transit_gateway.system_cloud_gateway_id
}
resource "aws_route" "private_route_to_on_premise_04" {
  #for_each               = local.availability_zones
  route_table_id         = aws_route_table.private_route_nat_table.id
  destination_cidr_block = local.edion_on_premise_04_cidr
  transit_gateway_id     = var.transit_gateway.system_cloud_gateway_id
}
resource "aws_route" "private_route_to_on_premise_05" {
  #for_each               = local.availability_zones
  route_table_id         = aws_route_table.private_route_nat_table.id
  destination_cidr_block = local.edion_on_premise_05_cidr
  transit_gateway_id     = var.transit_gateway.system_cloud_gateway_id
}
resource "aws_route" "private_route_to_on_premise_06" {
  #for_each               = local.availability_zones
  route_table_id         = aws_route_table.private_route_nat_table.id
  destination_cidr_block = local.edion_on_premise_06_cidr
  transit_gateway_id     = var.transit_gateway.system_cloud_gateway_id
}
resource "aws_route_table_association" "private_route_nat" {
  for_each       = local.availability_zones
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private_route_nat_table.id
}
