
locals {
  oracle = {
    subsystem           = "migration-test"
    subsystem_prefix    = "${local.resource_prefix}-migration-test-oracle"
    instance_class      = "db.t3.micro"
    rds_master_username = "dbuser"
    db_name             = "ORCL"

    instance_parameter_group_dynamic = {
      # "log_statement" = "none"
    }
  }
}


resource "aws_db_instance" "oracle" {
  apply_immediately = true
  engine            = "oracle-ee"
  # engine_version    = "12.1.0.2.v1"
  engine_version    = "12.1.0.2.v27"
  instance_class    = local.oracle.instance_class
  identifier        = local.oracle.subsystem_prefix
  username          = local.oracle.rds_master_username
  db_name           = local.oracle.db_name
  password          = data.aws_ssm_parameter.migration_test_rds_password.value

  allocated_storage     = 50
  max_allocated_storage = 100
  storage_type          = "gp2"


  parameter_group_name = aws_db_parameter_group.oracle_12.id
  db_subnet_group_name = data.aws_db_subnet_group.common.name
  option_group_name    = aws_db_option_group.oracle_12.id
  skip_final_snapshot  = true
  backup_window        = "21:00-21:30"
  maintenance_window   = "Mon:19:00-Mon:20:00"

  vpc_security_group_ids = [aws_security_group.common_sg.id]
}

# instance parameter_group
resource "aws_db_parameter_group" "oracle_12" {
  name   = "${local.oracle.subsystem_prefix}-instance-or12"
  family = "oracle-ee-12.1"

  dynamic "parameter" {
    for_each = local.oracle.instance_parameter_group_dynamic
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}

resource "aws_db_option_group" "oracle_12" {
  name                     = "${local.oracle.subsystem_prefix}-instance-or12"
  option_group_description = "Terraform Option Group"
  engine_name              = "oracle-ee"
  major_engine_version     = "12.1"

  #option {
  #  option_name = "Timezone"
  #  option_settings {
  #    name  = "TIME_ZONE"
  #    value = "UTC"
  #  }
  #}
}