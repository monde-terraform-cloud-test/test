locals {
  postgresql = {
    subsystem           = "db-01"
    subsystem_prefix    = "${local.resource_prefix}-db-01"
    database_name       = var.service_name
    instance_class      = "db.t3.medium" # "db.r5.4xlarge"
    rds_master_username = "dbuser"
    instance_count      = 2
    cloudwatch_log_retention_in_days = 365

    cluster_parameter_group_dynamic = {
      # "timezone" = "Asia/Tokyo"
      "log_min_duration_statement" = 1000 # NEW_EC_INFRA-98 slow query閾値設定
    }
    instance_parameter_group_dynamic = {
      # "log_statement" = "none"
    }
  }

}

# rds cluster
data "aws_ssm_parameter" "db_01_rds_password" {
  name = "/${local.env}/db-01/DB_PASSWORD"
}
resource "aws_rds_cluster" "postgresql" {
  apply_immediately               = true
  cluster_identifier              = local.postgresql.subsystem_prefix
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
  backup_retention_period         = local.env == "prd" ? 7 : 1
  copy_tags_to_snapshot           = true
  deletion_protection             = local.env == "prd" ? true : false
  skip_final_snapshot             = true
  preferred_backup_window         = "21:00-21:30"
  preferred_maintenance_window    = "Mon:19:00-Mon:20:00"
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.postgresql_13.id
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name = local.postgresql.subsystem_prefix
  }

  lifecycle {
    ignore_changes = [
      master_password,
      availability_zones
    ]
  }
}

# rds instance
resource "aws_rds_cluster_instance" "postgresql" {
  apply_immediately            = true
  count                        = local.postgresql.instance_count
  identifier_prefix            = "${local.postgresql.subsystem_prefix}-"
  cluster_identifier           = aws_rds_cluster.postgresql.id
  instance_class               = local.postgresql.instance_class
  engine                       = "aurora-postgresql"
  engine_version               = "13.6"
  performance_insights_enabled = local.env == "prd" ? true : false
  preferred_maintenance_window = "Mon:20:00-Mon:21:00"
  db_parameter_group_name      = aws_db_parameter_group.postgresql_13.id
  auto_minor_version_upgrade   = false

  tags = {
    Name = "${local.postgresql.subsystem_prefix}-${count.index}"
  }
}

# cluster parameter_group
resource "aws_rds_cluster_parameter_group" "postgresql_13" {
  name   = "${local.postgresql.subsystem_prefix}-cluster-pg13"
  family = "aurora-postgresql13"

  dynamic "parameter" {
    for_each = local.postgresql.cluster_parameter_group_dynamic
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  # dynamic parameter {
  #  for_each = local.postgresql.postgres_cluster_parameter_group_static
  #   content {
  #     apply_method = "pending-reboot"
  #     name         = parameter.key
  #     value        = parameter.value
  #   }
  # }
}

# instance parameter_group
resource "aws_db_parameter_group" "postgresql_13" {
  name   = "${local.postgresql.subsystem_prefix}-instance-pg13"
  family = "aurora-postgresql13"

  dynamic "parameter" {
    for_each = local.postgresql.instance_parameter_group_dynamic
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}

/* route53 private record
resource "aws_route53_record" "postgresql_rds_writer" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "db-01-writer.${local.private_hosted_zone_name}"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_rds_cluster.postgresql.endpoint]
}
resource "aws_route53_record" "postgresql_rds_reader" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "db-01-reader.${local.private_hosted_zone_name}"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_rds_cluster.postgresql.reader_endpoint]
}
*/

# cloudwatch logs
resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/cluster/${local.postgresql.subsystem_prefix}/postgresql"
  retention_in_days = local.postgresql.cloudwatch_log_retention_in_days

  tags = {
    Name = "/aws/rds/cluster/${local.postgresql.subsystem_prefix}/postgresql"
  }
}