/* アカウント情報系 */
data "aws_caller_identity" "current" {} # account idの取得: data.aws_caller_identity.current.account_id
data "aws_canonical_user_id" "current_user" {}
data "aws_region" "current" {} # region取得: data.aws_region.current.name

/* VPC: 既存リソースを利用 */
data "aws_vpc" "vpc" {
  default = false
  state   = "available"
  filter {
    name   = "tag:Name"
    values = ["${local.resource_prefix}-vpc"]
  }
}

data "aws_subnet" "main" {
  for_each = {
    # public_a  = "public-route-igw-1a"
    # public_c  = "public-route-igw-1c"
    # private_a = "private-route-nat-1a"
    # private_c = "private-route-nat-1c"
    public_a  = "public-1a"
    public_c  = "public-1c"
    private_a = "private-1a"
    private_c = "private-1c"
  }
  filter {
    name   = "tag:Name"
    values = ["${local.resource_prefix}-${each.value}"]
  }
}

data "aws_subnet" "public" {
  for_each = {
    0 = "public-1a"
    1 = "public-1c"
  }
  filter {
    name   = "tag:Name"
    values = ["${local.resource_prefix}-${each.value}"]
  }
}

data "aws_subnet" "private" {
  for_each = {
    0 = "private-1a"
    1 = "private-1c"

  }
  filter {
    name   = "tag:Name"
    values = ["${local.resource_prefix}-${each.value}"]
  }
}

/* iam */
data "aws_iam_role" "common" {
  for_each = {
    ecs_task_execution = "${local.resource_prefix}-ecs-task-execution"
    codebuild          = "${local.resource_prefix}-codebuild"
    codepipeline       = "${local.resource_prefix}-codepipeline"

  }
  name = each.value
}

data "aws_iam_policy" "common" {
  for_each = {
    ecs_exec   = "${local.resource_prefix}-ecs-exec"
    common_ecs = "${local.resource_prefix}-common-ecs"

  }
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${each.value}"
}

/* RDS */
data "aws_db_subnet_group" "common" {
  name = "${local.resource_prefix}-common-db-subnet-group"
}

/* assumerole */
data "aws_iam_policy_document" "assumerole" {
  for_each = toset([
    "ecs-tasks",
    "firehose",
    "ec2",
    "lambda",
    "codebuild",
    "codepipeline",
    "monitoring.rds",
    "events",
    "glue",
  ])
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["${each.key}.amazonaws.com"]
    }
  }
}

data "aws_s3_bucket" "common" {
  for_each = {
    server_log        = "${local.resource_prefix}-server-log"
    elb_log           = "${local.resource_prefix}-elb-log"
    ecs_exec_log      = "${local.resource_prefix}-ecs-exec-log"
    user_upload_image = "${local.resource_prefix}-user-upload-image"
    csv               = "${local.resource_prefix}-csv"
    html              = "${local.resource_prefix}-html"
    #movie             = "${local.resource_prefix}-movie"
    config            = "${local.resource_prefix}-config"
    image             = "${local.resource_prefix}-image"
    #temporary         = "${local.resource_prefix}-temporary"
    special           = "${local.resource_prefix}-special"
    mail              = "${local.resource_prefix}-mail"
    migration_tools   = "${local.resource_prefix}-migration-tools"
  }
  bucket = each.value
}

/* SG */
data "aws_security_group" "common" {
  for_each = {
    common_sg = "${local.resource_prefix}-common"
  }
  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}

# AMIs
data "aws_ami" "amazonlinux2_latest" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20220426.0-x86_64-gp2"]
  }
}

/* ACM */
data "aws_acm_certificate" "service_domain_cert_ap_northeast_1" {
  domain = "*.${local.domains.service}"
}
