resource "aws_security_group" "common_sg" {
  name        = "${local.resource_prefix}-migration-test-common"
  description = "${local.resource_prefix}-migration-test-common"
  vpc_id      = data.aws_vpc.vpc.id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.resource_prefix}-migration-test-common"
  }
}