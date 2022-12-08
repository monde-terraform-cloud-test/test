# stgのresolverを参照するのでresolverは不要

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
