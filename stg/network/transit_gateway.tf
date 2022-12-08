/* attachment コンソール操作したためresource無効化
resource "aws_ec2_transit_gateway_vpc_attachment" "system_cloud" {
  subnet_ids = [
    aws_subnet.private["0"].id,
    aws_subnet.private["1"].id,
  ]
  transit_gateway_id                              = var.transit_gateway.system_cloud_gateway_id
  vpc_id                                          = aws_vpc.vpc.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

# association:ルートテーブルとアタッチメントの関連付け / transit gateway接続元アカウントで作成するリソースのため不要
resource "aws_ec2_transit_gateway_route_table_association" "system_cloud" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.system_cloud.id
  transit_gateway_route_table_id = var.transit_gateway.system_cloud_gateway_route_table_id
}
# propagation:アタッチメントからルートテーブルへのルートの伝播 / transit gateway接続元アカウントで作成するリソースのため不要
resource "aws_ec2_transit_gateway_route_table_propagation" "system_cloud" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.system_cloud.id
  transit_gateway_route_table_id = var.transit_gateway.system_cloud_gateway_route_table_id
}
*/