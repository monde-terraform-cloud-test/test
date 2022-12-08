/* NEW_EC_INFRA-112
バッチ動作確認用DB
復元元スナップショット rds:edion-ecsite-stg-db-01-2022-08-29-21-05
*/

/* 2022/11/30 削除
locals {
  postgresql_clone = {
    cluster_parameter_group_dynamic = {
      # "timezone" = "Asia/Tokyo"
      "log_min_duration_statement" = 1000 # NEW_EC_INFRA-98 slow query閾値設定
      "log_statement"              = "all"
    }
  }
}
resource "aws_rds_cluster" "postgresql_clone" {
  snapshot_identifier             = "arn:aws:rds:ap-northeast-1:681446296757:cluster-snapshot:rds:edion-ecsite-stg-db-01-2022-08-29-21-05"
  apply_immediately               = true
  cluster_identifier              = "${local.postgresql.subsystem_prefix}-clone"
  engine                          = "aurora-postgresql"
  engine_version                  = "13.6"
  engine_mode                     = "provisioned"
  database_name                   = local.postgresql.database_name
  master_username                 = local.postgresql.rds_master_username
  master_password                 = data.aws_ssm_parameter.db_01_rds_password.value
  storage_encrypted               = false
  db_subnet_group_name            = data.aws_db_subnet_group.common.name
  vpc_security_group_ids          = [
    data.aws_security_group.common["common_sg"].id,
    aws_security_group.rds.id,
  ]
  port                            = 5432
  backup_retention_period         = 8 # 開発中のrevert可能性あるため
  # backup_retention_period         = local.env == "prod" ? 7 : 1
  copy_tags_to_snapshot           = true
  deletion_protection             = local.env == "prod" ? true : false
  skip_final_snapshot             = true
  preferred_backup_window         = "21:00-21:30"
  preferred_maintenance_window    = "Mon:19:00-Mon:20:00"
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.postgresql_13_clone.id
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name = "${local.postgresql.subsystem_prefix}-clone"
  }

  lifecycle {
    ignore_changes = [
      master_password,
      availability_zones
    ]
  }
}

# rds instance
resource "aws_rds_cluster_instance" "postgresql_clone" {
  apply_immediately            = true
  count                        = local.postgresql.instance_count_clone
  identifier_prefix            = "${local.postgresql.subsystem_prefix}-clone-"
  cluster_identifier           = aws_rds_cluster.postgresql_clone.id
  instance_class               = local.postgresql.instance_class_clone
  engine                       = "aurora-postgresql"
  engine_version               = "13.6"
  performance_insights_enabled = local.env == "prod" ? true : false
  preferred_maintenance_window = "Mon:20:00-Mon:21:00"
  db_parameter_group_name      = aws_db_parameter_group.postgresql_13.id
  auto_minor_version_upgrade   = false

  tags = {
    Name = "${local.postgresql.subsystem_prefix}-clone-${count.index}"
  }
}

# cluster parameter_group
resource "aws_rds_cluster_parameter_group" "postgresql_13_clone" {
  name   = "${local.postgresql.subsystem_prefix}-cluster-pg13-clone"
  family = "aurora-postgresql13"

  dynamic "parameter" {
    for_each = local.postgresql_clone.cluster_parameter_group_dynamic
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}

# cloudwatch logs
resource "aws_cloudwatch_log_group" "postgresql_clone" {
  name              = "/aws/rds/cluster/${local.postgresql.subsystem_prefix}-clone/postgresql"
  retention_in_days = local.postgresql.cloudwatch_log_retention_in_days

  tags = {
    Name = "/aws/rds/cluster/${local.postgresql.subsystem_prefix}-clone/postgresql"
  }
}
*/