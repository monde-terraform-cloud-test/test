locals {
  # ※ aws_ecs_task_definition の更新後は Force Deploy を実行すること
  #   反映した状態でないと次回 CodePipeline でのデプロイ時に未反映となる
  # - desired_count : 初期作成時の値。以降は ecs.tf の min_capacity, max_capacity で Auto Scaling に定義
  ecs_service = {
    cpu                              = 256
    memory                           = 512
    desired_count                    = 1
    target_group_arn                 = aws_lb_target_group.alb_role_internal.arn
    cloudwatch_log_retention_in_days = 7
    capacity_provider                = "FARGATE"

  }
  # 承認機能を付与するか否か
  codepipeline_approval = false
}
/*

module "ecs_scaling" {
  source = "../../../_module/ecs-target-tracking-scaling"

  ecs_cluster_name = module.ecs.ecs_cluster_name
  ecs_service_name = aws_ecs_service.role["main"].name
  min_capacity     = 1
  max_capacity     = 1

  ecs_service_average_cpu_utilization = {
    target_value       = 60
    disable_scale_in   = "false"
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }

  ecs_service_average_memory_utilization = {
    target_value       = 60
    disable_scale_in   = "false"
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }

  alb_request_count_per_target = {
    target_value       = 0
    disable_scale_in   = "false"
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
    load_balancer_arn  = aws_lb.alb_role.arn
    target_group_arn   = aws_lb_target_group.alb_role_main.arn
  }
}
*/

resource "aws_ecs_cluster" "role" {
  name = local.role_prefix

  setting {
    name  = "containerInsights"
    value = "disabled"
    # value = var.container_insights ? "enabled" : "disabled"
  }

  tags = {
    "Name" = local.role_prefix
  }
}

resource "aws_iam_role" "ecs_task" {
  name               = "${local.role_prefix}-ecs"
  assume_role_policy = data.aws_iam_policy_document.assumerole["ecs-tasks"].json
}
resource "aws_iam_role_policy_attachment" "ecs_task" {
  for_each = {
    SSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ecs_exec               = data.aws_iam_policy.common["ecs_exec"].arn
    common_ecs             = data.aws_iam_policy.common["common_ecs"].arn
    # ecs_task                   = aws_iam_policy.ecs_task.arn
  }
  role       = aws_iam_role.ecs_task.name
  policy_arn = each.value
}

/* 個別で権限付与する場合に追加
resource "aws_iam_policy" "ecs_task" {
  name        = local.role_prefix
  description = local.role_prefix
  path        = "/"
  policy      = data.aws_iam_policy_document.ecs_task.json
  tags = {
    Roles = local.role_prefix
  }
}
data "aws_iam_policy_document" "ecs_task" {
  statement {
    sid = "1"
    actions = [

    ]
    effect    = "Allow"
    resources = ["*"]
  }
}
*/

/* ECS Service */
resource "aws_cloudwatch_log_group" "role" {
  name              = "/ecs/${local.role_prefix}"
  retention_in_days = local.ecs_service.cloudwatch_log_retention_in_days

  tags = {
    Name = "/ecs/${local.role_prefix}"
  }
}

data "aws_ecs_task_definition" "role_latest" {
  task_definition = aws_ecs_task_definition.role.family
}

resource "aws_ecs_task_definition" "role" {

  family = local.role_prefix

  cpu                      = local.ecs_service.cpu
  memory                   = local.ecs_service.memory
  execution_role_arn       = data.aws_iam_role.common["ecs_task_execution"].arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      "name" : "${local.role_prefix}",
      "image" : "${aws_ecr_repository.role.repository_url}:latest",
      "essential" : true,
      "environmentFiles" : [
        {
          "value" : "arn:aws:s3:::${local.resource_prefix}-config/${var.role}/develop.env",
          "type" : "s3"
        }
      ],
      "portMappings" : [
        {
          "hostPort" : 8080,
          "protocol" : "tcp",
          "containerPort" : 8080
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "/ecs/${local.role_prefix}",
          "awslogs-region" : data.aws_region.current.name,
          "awslogs-stream-prefix" : var.role
        }
      },
      "linuxParameters" : {
        "initProcessEnabled" : true
      },
      "workingDirectory" : "/var/www/html"
    },
  ])

  tags = {
    Name  = local.role_prefix
    Roles = var.role
  }
}

resource "aws_ecs_service" "role" {
  lifecycle {
    ignore_changes = [
      platform_version,
      task_definition,
      desired_count,
    ]
  }

  name            = local.role_prefix
  cluster         = aws_ecs_cluster.role.arn
  task_definition = "${aws_ecs_task_definition.role.family}:${max(aws_ecs_task_definition.role.revision, data.aws_ecs_task_definition.role_latest.revision)}"

  desired_count                     = local.ecs_service.desired_count
  health_check_grace_period_seconds = 0
  capacity_provider_strategy {
    capacity_provider = local.ecs_service.capacity_provider
    weight            = 1
    base              = 0
  }
  platform_version    = "LATEST"
  scheduling_strategy = "REPLICA"
  network_configuration {
    assign_public_ip = false
    security_groups = [
      aws_security_group.ecs_role.id,
      data.aws_security_group.common["common_sg"].id,
    ]
    subnets = [
      data.aws_subnet.main["private_a"].id,
      data.aws_subnet.main["private_c"].id,
    ]
  }
  deployment_controller {
    type = "ECS"
  }
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.alb_role_internal.arn
    container_name   = local.role_prefix
    container_port   = 8080
  }

  propagate_tags          = "TASK_DEFINITION"
  enable_ecs_managed_tags = true
  enable_execute_command  = true

  tags = {
    Name = "${local.role_prefix}"
  }
}
