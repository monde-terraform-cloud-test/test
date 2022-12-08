################################################################################
# S3 Bucket
################################################################################
resource "aws_s3_bucket" "codepipeline" {
  bucket = "${local.role_prefix}-codepipeline"

  force_destroy = false
  tags = {
    Name = "${local.role_prefix}-codepipeline"
  }
}
resource "aws_s3_bucket_acl" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id
  acl    = "private"
}
resource "aws_s3_bucket_versioning" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline" {
  depends_on = [aws_s3_bucket.codepipeline]
  bucket     = aws_s3_bucket.codepipeline.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.codepipeline.id
  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
}

#################
# imagedefinitions
#################
resource "local_file" "imagedefinitions_buildspec" {
  content = templatefile("../../_template/buildspec_imagedefinitions.yml", {
    container_name_prefix = "${local.role_prefix}",
    stages                = "main"
  })
  filename             = "./_imagedefinitions_buildspec/buildspec.yml"
  file_permission      = "0644"
  directory_permission = "0755"
}

data "archive_file" "imagedefinitions_buildspec" {
  depends_on = [
    local_file.imagedefinitions_buildspec,
  ]

  type        = "zip"
  source_dir  = "./_imagedefinitions_buildspec"
  output_path = "./var/_imagedefinitions_buildspec/imagedefinitions_buildspec.zip"
}

resource "aws_s3_object" "imagedefinitions_buildspec" {
  depends_on = [
    aws_s3_bucket.codepipeline,
    local_file.imagedefinitions_buildspec,
    data.archive_file.imagedefinitions_buildspec,
  ]

  bucket = "${local.role_prefix}-codepipeline"
  key    = "imagedefinitions_buildspec.zip"
  source = data.archive_file.imagedefinitions_buildspec.output_path
  etag   = fileexists(data.archive_file.imagedefinitions_buildspec.output_path) ? data.archive_file.imagedefinitions_buildspec.output_md5 : null
}

################################################################################
# CodeBuild (imagedefinitions.json)
################################################################################
resource "aws_codebuild_project" "imagedefinitions" {
  name          = "${local.role_prefix}-imagedefinitions"
  description   = "create imagedefinitions.json"
  build_timeout = "5"
  badge_enabled = false
  service_role  = data.aws_iam_role.common["codebuild"].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    modes = []
    type  = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      status = "DISABLED"
    }
  }

  source {
    type     = "S3"
    location = "${aws_s3_object.imagedefinitions_buildspec.bucket}/${aws_s3_object.imagedefinitions_buildspec.key}"
  }

  tags = {
    Name = "${local.role_prefix}-imagedefinitions"
  }
}

resource "aws_cloudwatch_log_group" "codebuild_imagedefinitions" {
  name              = "/aws/codebuild/${aws_codebuild_project.imagedefinitions.name}"
  retention_in_days = 30
}

#################
# CodePipeline
#################
resource "aws_codepipeline" "codepipeline_ecs" {
  name     = "${local.role_prefix}-ecs"
  role_arn = data.aws_iam_role.common["codepipeline"].arn

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      namespace        = "SourceVariables"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        PollForSourceChanges = "false"
        S3Bucket             = aws_s3_object.imagedefinitions_buildspec.bucket
        S3ObjectKey          = aws_s3_object.imagedefinitions_buildspec.key
      }
    }

    action {
      name             = "Image"
      namespace        = "ImageVariables"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["ImageArtifact"]

      configuration = {
        ImageTag       = "latest"
        RepositoryName = local.role_prefix
      }
    }
  }

  stage {
    name = "Build"

    action {
      name      = "imagedefinitions"
      namespace = "imagedefinitionsVariables"
      category  = "Build"
      owner     = "AWS"
      provider  = "CodeBuild"
      input_artifacts = [
        "SourceArtifact",
        "ImageArtifact",
      ]
      output_artifacts = [
        "imagedefinitionsArtifact",
      ]
      version = "1"

      configuration = {
        PrimarySource = "SourceArtifact"
        ProjectName   = aws_codebuild_project.imagedefinitions.name
      }
    }
  }

  dynamic "stage" {
    for_each = local.codepipeline_approval ? [true] : []
    content {
      name = "Approval"

      action {
        name     = "Approval"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = {
          NotificationArn = module.sns_topic_codepipeline_ecs_approval[0].arn
        }
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      namespace       = "DeployVariables"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["imagedefinitionsArtifact"]
      version         = "1"

      configuration = {
        ClusterName       = local.role_prefix
        ServiceName       = "${local.role_prefix}"
        FileName          = "imagedefinitions/main.json"
        DeploymentTimeout = 5
      }
    }
  }
}

#################
# CodePipeline Notifications
#################
resource "aws_sns_topic" "codepipeline_ecs" {
  name = "${local.role_prefix}-codepipeline-ecs"
  tags = {
    "Name" = "${local.role_prefix}-codepipeline-ecs"
  }
}
resource "aws_sns_topic_policy" "codepipeline_ecs" {
  arn    = aws_sns_topic.codepipeline_ecs.arn
  policy = data.aws_iam_policy_document.codepipeline_ecs.json
}
data "aws_iam_policy_document" "codepipeline_ecs" {
  statement {
    sid = "__default_statement_ID"

    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive",
    ]

    effect = "Allow"

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "${data.aws_caller_identity.current.account_id}",
      ]
    }

    resources = [
      aws_sns_topic.codepipeline_ecs.arn,
    ]
  }

  dynamic "statement" {
    for_each = {
      codestar-notifications = "codestar-notifications.amazonaws.com"
      events                 = "events.amazonaws.com"
    }

    content {
      sid     = statement.key
      actions = ["SNS:Publish"]
      effect  = "Allow"
      principals {
        identifiers = [statement.value]
        type        = "Service"
      }
      resources = [aws_sns_topic.codepipeline_ecs.arn]
    }
  }
}

resource "aws_codestarnotifications_notification_rule" "codepipeline_ecs" {
  detail_type    = "FULL"
  event_type_ids = local.codepipeline_event_type_ids

  name     = "${local.role_prefix}-codepipeline-ecs"
  resource = aws_codepipeline.codepipeline_ecs.arn

  target {
    address = aws_sns_topic.codepipeline_ecs.arn
  }
  tags = {
    Name = "${local.role_prefix}-codepipeline-ecs"
  }
}

#################
# CloudWatch Event (EventBridge)
#################
resource "aws_cloudwatch_event_rule" "codepipeline_ecs" {
  name        = "${local.role_prefix}-codepipeline-ecs"
  description = "Automatically start your pipeline when a change occurs in the Amazon ECR image tag."
  is_enabled  = true

  event_pattern = templatefile("../../_template/codepipeline_image_tag_changes.json", {
    image_tag       = "latest"
    repository_name = aws_ecr_repository.role.name
  })

  tags = {
    Name = "${local.role_prefix}-codepipeline-ecs"
  }
}

resource "aws_cloudwatch_event_target" "codepipeline_ecs" {
  rule     = aws_cloudwatch_event_rule.codepipeline_ecs.name
  arn      = aws_codepipeline.codepipeline_ecs.arn
  role_arn = data.aws_iam_role.codepipeline_cwe.arn
}
data "aws_iam_role" "codepipeline_cwe" {
  name = "${local.resource_prefix}-codepipeline-cwe"
}
