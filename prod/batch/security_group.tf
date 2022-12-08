resource "aws_security_group" "ec2_role" {
  name        = "${local.role_prefix}-ec2"
  description = "${local.role_prefix}-ec2"
  vpc_id      = data.aws_vpc.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.role_prefix}-ec2"
  }
}

resource "aws_security_group_rule" "ec2_role_tgw" {
  for_each = {
    edion_system_cloud_tgw = [local.edion_system_cloud_cidr]
    edion_on_premise_tgw   = [local.edion_on_premise_01_cidr,local.edion_on_premise_02_cidr,local.edion_on_premise_03_cidr]
  }
  type              = "ingress"
  description       = each.key
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = each.value
  security_group_id = aws_security_group.ec2_role.id
}
