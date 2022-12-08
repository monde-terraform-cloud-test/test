/* redis */
locals {
  redis = {
    subsystem        = "redis-01"
    subsystem_prefix = "${local.resource_prefix}-redis-01"

    node_type          = "cache.r5.large"
    engine_version     = "6.2"
    num_cache_clusters = 1
    maintenance_window = "Wed:18:30-Wed:19:30"
    snapshot_window    = "21:00-22:00"
  }
}

resource "aws_elasticache_replication_group" "redis" {

  replication_group_id       = local.redis.subsystem_prefix
  description                = local.redis.subsystem_prefix
  node_type                  = local.redis.node_type
  num_cache_clusters         = local.redis.num_cache_clusters
  engine_version             = local.redis.engine_version
  port                       = 6379
  parameter_group_name       = aws_elasticache_parameter_group.redis6x.id
  security_group_ids         = [data.aws_security_group.common["common_sg"].id]
  subnet_group_name          = aws_elasticache_subnet_group.redis.id
  automatic_failover_enabled = local.env == "prod" ? true : false
  multi_az_enabled           = local.env == "prod" ? true : false
  maintenance_window         = local.redis.maintenance_window
  snapshot_window            = local.redis.snapshot_window
  snapshot_retention_limit   = local.env == "prod" ? 7 : 1
  apply_immediately          = true
  tags = {
    Roles = local.redis.subsystem
  }
}
/*
resource "aws_route53_record" "redis_primary" {

  zone_id = data.aws_route53_zone.private.zone_id
  name    = "${local.redis.subsystem}-redis.${local.private_hosted_zone_name}"
  type    = "CNAME"
  ttl     = 10
  records = [aws_elasticache_replication_group.redis.primary_endpoint_address]
}

resource "aws_route53_record" "redis_reader" {

  zone_id = data.aws_route53_zone.private.zone_id
  name    = "${local.redis.subsystem}-redis-ro.${local.private_hosted_zone_name}"
  type    = "CNAME"
  ttl     = 10
  records = [aws_elasticache_replication_group.redis.reader_endpoint_address]
}
*/