locals {
  edion-new-ec          = "andgate-corp/edion-new-ec"
  edion-ecmigrate-tools = "andgate-corp/edion-ecmigrate-tools"
}

## oidc provider
resource "aws_iam_openid_connect_provider" "main" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# edion-new-ec
## role
data "aws_iam_policy_document" "github_oid_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.main.arn]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.edion-new-ec}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${local.resource_prefix}-github_actions-oidc-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.github_oid_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  for_each   = {
    github_actions = aws_iam_policy.github_actions.arn
  }
  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}

## policy
data "aws_iam_policy_document" "github_actions" {
  ## allow running `aws sts get-caller-identity`
  statement {
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  ## allow ECR action
    statement {
    effect    = "Allow"
    actions   = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:ListImages",
        "ecr:CompleteLayerUpload",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetAuthorizationToken",
        ]
    resources = ["*"]
  }

  ## allow SSM action
    statement {
    effect    = "Allow"
    actions   = [
        "iam:PassRole",
        ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "${local.resource_prefix}-github_actions_policy"
  path        = "/"
  description = "Policy for GitHubActions"
  policy      = data.aws_iam_policy_document.github_actions.json
}

# migration-tool
# NEW_EC_INFRA-140
resource "aws_iam_role" "migration" {
  name               = "${local.resource_prefix}-migration-tool-deploy"
  assume_role_policy = data.aws_iam_policy_document.assumerole_migration.json

  tags = {
    Name = "${local.resource_prefix}-migration-tool-deploy"
  }
}

data "aws_iam_policy_document" "assumerole_migration" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.main.arn]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.edion-ecmigrate-tools}:*"]
    }
  }
}


resource "aws_iam_policy" "migration" {
  name   = "${local.resource_prefix}-migration-tool-deploy"
  policy = data.aws_iam_policy_document.migration.json
}

data "aws_iam_policy_document" "migration" {
  statement {
    sid    = "VisualEditor0"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${local.resource_prefix}-migration-tools/*",
    ]
  }

  statement {
    sid    = "VisualEditor1"
    effect = "Allow"
    actions = [
        "ssm:*",
        "ec2:describeInstances",
        "iam:ListRoles"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "VisualEditor2"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "ssm.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "migration" {
  for_each = {
    migration-tool-deploy    = aws_iam_policy.migration.arn
  }
  role       = aws_iam_role.migration.name
  policy_arn = each.value
}
