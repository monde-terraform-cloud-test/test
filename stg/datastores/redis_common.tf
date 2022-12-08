resource "aws_elasticache_subnet_group" "redis" {
  name = "${local.resource_prefix}-cache-subnet-group"
  subnet_ids = [
    data.aws_subnet.main["private_a"].id,
    data.aws_subnet.main["private_c"].id,
    # data.aws_subnet.private_d.id
  ]
  tags = {
    Name = "${local.resource_prefix}-cache-subnet-group"
  }
}

resource "aws_elasticache_parameter_group" "redis6x" {
  name   = "${local.resource_prefix}-redis6x"
  family = "redis6.x"
}
resource "aws_elasticache_parameter_group" "redis6x_cluster" {
  name        = "${local.resource_prefix}-redis6x-cluster"
  description = "cluster mode parameter group"
  family      = "redis6.x"

  parameter {
    name  = "cluster-enabled"
    value = "yes"
  }
}