/* route53_resolver */

locals {
  route53_resolver_aws_security_group_rule_for_each = {
    #tgw = [local.tgw_cidr]
    edion_dns_server01 = [local.source_ip_address_edion_dns_server01]
    edion_dns_server02 = [local.source_ip_address_edion_dns_server02]
  }

  route53_outbound_aws_security_group_rule_for_each = {
    prd_vpc_cidr = [local.vpc_cidr]
    stg_vpc_cidr = [local.stg_vpc_cidr]
    dev_vpc_cidr = [local.dev_vpc_cidr]
  }
}

resource "aws_security_group" "route53_resolver" {
  name        = "${local.resource_prefix}-route53-resolver"
  description = "${local.resource_prefix}-route53-resolver"
  vpc_id      = data.aws_vpc.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.resource_prefix}-route53-resolver"
  }
}

resource "aws_security_group_rule" "route53_resolver_rule_ingress_tcp" {
  for_each = local.route53_resolver_aws_security_group_rule_for_each

  type              = "ingress"
  description       = each.key
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = each.value
  security_group_id = aws_security_group.route53_resolver.id
}
resource "aws_security_group_rule" "route53_resolver_rule_ingress_udp" {
  for_each = local.route53_resolver_aws_security_group_rule_for_each

  type              = "ingress"
  description       = each.key
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = each.value
  security_group_id = aws_security_group.route53_resolver.id
}
resource "aws_security_group_rule" "route53_resolver_rule_ingress_icmp" {
  for_each = local.route53_resolver_aws_security_group_rule_for_each

  type              = "ingress"
  description       = each.key
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = each.value
  security_group_id = aws_security_group.route53_resolver.id
}

resource "aws_security_group" "route53_outbound" {
  name        = "${local.resource_prefix}-route53-outbound"
  description = "${local.resource_prefix}-route53-outbound"
  vpc_id      = data.aws_vpc.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.resource_prefix}-route53-outbound"
  }
}

resource "aws_security_group_rule" "route53_outbound_rule_ingress_tcp" {
  for_each = local.route53_outbound_aws_security_group_rule_for_each

  type              = "ingress"
  description       = each.key
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = each.value
  security_group_id = aws_security_group.route53_outbound.id
}
resource "aws_security_group_rule" "route53_outbound_rule_ingress_udp" {
  for_each = local.route53_outbound_aws_security_group_rule_for_each

  type              = "ingress"
  description       = each.key
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = each.value
  security_group_id = aws_security_group.route53_outbound.id
}
resource "aws_security_group_rule" "route53_outbound_rule_ingress_icmp" {
  for_each = local.route53_outbound_aws_security_group_rule_for_each

  type              = "ingress"
  description       = each.key
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = each.value
  security_group_id = aws_security_group.route53_outbound.id
}

/* common */
resource "aws_security_group" "common_sg" {
  name        = "${local.resource_prefix}-common"
  description = "${local.resource_prefix}-common"
  vpc_id      = data.aws_vpc.vpc.id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  tags = {
    Name = "${local.resource_prefix}-common"
  }
}
