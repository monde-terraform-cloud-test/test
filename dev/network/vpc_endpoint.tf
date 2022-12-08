# S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  tags = {
    Name = "${local.resource_prefix}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  for_each        = local.availability_zones
  route_table_id  = aws_route_table.public_route_igw_table[each.key].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}
resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  route_table_id  = aws_route_table.private_route_nat_table.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}
