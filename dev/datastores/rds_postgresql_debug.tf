# NEW_EC_INFRA-148

# rds instance
## Frontデバッグ用及びECBOデバッグ用。failoverで状況変わる可能性あるため個別の命名は避ける。
resource "aws_rds_cluster_instance" "postgresql_debug" {
  apply_immediately            = true
  count                        = 2
  identifier_prefix            = "${local.postgresql.subsystem_prefix}-"
  cluster_identifier           = aws_rds_cluster.postgresql.id
  instance_class               = "db.t3.medium"
  engine                       = "aurora-postgresql"
  engine_version               = "13.6"
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  # performance_insights_enabled = local.env == "prod" ? true : false
  preferred_maintenance_window = "Mon:20:00-Mon:21:00"
  db_parameter_group_name      = aws_db_parameter_group.postgresql_13.id
  auto_minor_version_upgrade   = false
  promotion_tier               = 1 # failover優先度

  tags = {
    Name = "${local.postgresql.subsystem_prefix}-${count.index}"
  }
}
