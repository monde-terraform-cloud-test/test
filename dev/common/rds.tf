# subnet group
resource "aws_db_subnet_group" "common" {
  name = "${local.resource_prefix}-common-db-subnet-group"
  subnet_ids = [
    data.aws_subnet.private[0].id,
    data.aws_subnet.private[1].id,
    # data.aws_subnet.private_d.id
  ]
  tags = {
    Name = "${local.resource_prefix}-common-db-subnet-group"
  }
  lifecycle {
    ignore_changes = [
      subnet_ids,
      ]
    }
}

# monitoring role
# iam role
resource "aws_iam_role" "rds_monitoring_role" {
  name               = "rds_monitoring_role"
  assume_role_policy = data.aws_iam_policy_document.assumerole["monitoring.rds"].json
}
# iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}