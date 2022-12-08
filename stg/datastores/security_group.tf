resource "aws_security_group" "rds" {
  name        = "${local.resource_prefix}-rds"
  description = "${local.resource_prefix}-rds"
  vpc_id      = data.aws_vpc.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.resource_prefix}-rds"
  }
}

resource "aws_security_group_rule" "rds_postgresql" {
  for_each = {
    edion_system_cloud_tgw = [local.edion_system_cloud_cidr]
  }
  type              = "ingress"
  description       = each.key
  from_port         = 5432
  to_port           = 5432
  protocol          = "TCP"
  cidr_blocks       = each.value
  security_group_id = aws_security_group.rds.id
}