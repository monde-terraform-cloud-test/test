################################################################################
# ECS
################################################################################
resource "aws_security_group" "ecs_role" {
  name        = "${local.role_prefix}-ecs"
  description = "${local.role_prefix}-ecs"
  vpc_id      = data.aws_vpc.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.role_prefix}-ecs"
  }
}

resource "aws_security_group_rule" "ecs_role" {
  description = "elb"
  type        = "ingress"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"

  source_security_group_id = aws_security_group.alb_role.id
  security_group_id        = aws_security_group.ecs_role.id
}

resource "aws_security_group_rule" "ecs_role_http_tmp" {
  description = "elb"
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"

  source_security_group_id = aws_security_group.alb_role.id
  security_group_id        = aws_security_group.ecs_role.id
}

################################################################################
# ALB
################################################################################
resource "aws_security_group" "alb_role" {
  name        = "${local.role_prefix}-alb"
  description = "${local.role_prefix}-alb"
  vpc_id      = data.aws_vpc.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.role_prefix}-alb"
  }
}

resource "aws_security_group_rule" "alb_role_https" {
  for_each = {
    # any      = ["0.0.0.0/0"]
    hampstead           = local.source_ip_address_hampstead
    edion_PC_Head_Store = local.source_ip_address_edion_PC_Head_Store
    edion_PC_GP         = local.source_ip_address_edion_PC_GP
    edion_Mobile_GP     = local.source_ip_address_edion_Mobile_GP
  }
  type        = "ingress"
  description = each.key
  from_port   = 80 # tmp rule
  # from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = each.value
  security_group_id = aws_security_group.alb_role.id
}
