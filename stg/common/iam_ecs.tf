## ecs task execution role
resource "aws_iam_role" "ecs_task_execution" {
  name               = "${local.resource_prefix}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.assumerole["ecs-tasks"].json
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  for_each = {
    base        = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    s3_readonly = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    datadog_getmetrics = aws_iam_policy.datadog_getmetrics.arn
  }
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = each.value
}

## [Using Amazon ECS Exec for debugging \- Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/userguide/ecs-exec.html#ecs-exec-enabling-and-using)
resource "aws_iam_policy" "ecs_exec" {
  name        = "${local.resource_prefix}-ecs-exec"
  description = "${local.resource_prefix}-ecs-exec"
  path        = "/"
  policy      = data.aws_iam_policy_document.ecs_exec.json
  lifecycle {
    ignore_changes = [
      policy,
    ]
  }
}
data "aws_iam_policy_document" "ecs_exec" {
  statement {
    sid    = "ssm"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "EnableLogCloudWatch"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "EnableLogS301"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "EnableLogS302"
    effect = "Allow"
    actions = [
      "s3:GetEncryptionConfiguration",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.bucket["ecs_exec_log"].arn}",
      "${aws_s3_bucket.bucket["ecs_exec_log"].arn}/*",
    ]
  }
}

resource "aws_iam_policy" "common_ecs" {
  name        = "${local.resource_prefix}-common-ecs"
  description = "${local.resource_prefix}-common-ecs"
  path        = "/"
  policy      = data.aws_iam_policy_document.common_ecs.json
}
data "aws_iam_policy_document" "common_ecs" {
  statement {
    sid = 1
    actions = [
      "ec2:Describe*",
      "secretsmanager:List*",
      "secretsmanager:Get*",
      "s3:List*",
      "s3:Get*",
      "ses:SendEmail",
      "ses:SendRawEmai",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "s3allow"
    actions = [
      "s3:Put*",
      "s3:DeleteObject",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersion",
      "s3:DeleteObjectVersionTagging",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "datadog_getmetrics" {
  name        = "DatadogEcsFargateGetMetrics"
  description = "DatadogEcsFargateGetMetrics"
  path        = "/"
  policy      = data.aws_iam_policy_document.datadog_getmetrics.json
}

data "aws_iam_policy_document" "datadog_getmetrics" {
  statement {
    sid    = "ECSGetmetrics"
    effect = "Allow"
    actions = [
      "ecs:ListClusters",
      "ecs:ListContainerInstances",
      "ecs:DescribeContainerInstances",
    ]
    resources = ["*"]
  }
    statement {
    sid    = "GetSecretValue"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:aws:secretsmanager:ap-northeast-1:681446296757:secret:DdApiKeySecret-HIeDWgeq81yF-zk7IyF",
      ]
  }
}