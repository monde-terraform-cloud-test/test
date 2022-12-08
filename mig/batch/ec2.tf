locals {
  al2 = {
    subsystem        = var.role
    subsystem_prefix = local.role_prefix
    ami_id           = data.aws_ami.amazonlinux2_latest.id
    instance_type    = "t3.large"
    ebs_optimized    = false
    root_volume_type = "gp3"
    root_volume_size = 100
  }

  key_name = "${local.resource_prefix}-common"

  ec2_for_each = {
    "1a-0" = data.aws_subnet.main["private_a"].id
    # "1c-0" = data.aws_subnet.main["private_c"].id
    # "1d-0" = data.aws_subnet.main["private_d"].id
  }
}


## EC2
resource "aws_instance" "al2" {
  for_each = local.ec2_for_each

  ami                  = local.al2.ami_id
  instance_type        = local.al2.instance_type
  key_name             = local.key_name
  iam_instance_profile = aws_iam_instance_profile.al2.name
  subnet_id            = each.value
  ebs_optimized        = local.al2.ebs_optimized
  vpc_security_group_ids = [
    data.aws_security_group.common["common_sg"].id,
    aws_security_group.ec2_role.id,
  ]
  associate_public_ip_address = false
  root_block_device {
    volume_type = local.al2.root_volume_type
    volume_size = local.al2.root_volume_size
  }
  tags = {
    Name  = "${local.role_prefix}-${each.key}"
    Roles = local.al2.subsystem
  }
  volume_tags = {
    Name = local.al2.subsystem_prefix
  }
}

resource "aws_iam_instance_profile" "al2" {
  name = local.al2.subsystem_prefix
  role = aws_iam_role.al2.name
  tags = {
    Roles = local.al2.subsystem
  }
}
resource "aws_iam_role" "al2" {
  name               = local.al2.subsystem_prefix
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assumerole["ec2"].json
  tags = {
    Roles = local.al2.subsystem
  }
}
/* aws_iam_role_policy_attachment
--target 'aws_iam_role_policy_attachment.al2["SSMManagedInstanceCore"]'
--target 'aws_iam_role_policy_attachment.al2["al2"]'
*/
resource "aws_iam_role_policy_attachment" "al2" {
  for_each = {
    SSMManagedInstanceCore   = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    al2                      = aws_iam_policy.al2.arn
    AmazonEC2RoleforSSM      = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
    AmazonSSMFullAccess      = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
    AmazonS3FullAccess       = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    CloudWatchFullAccess     = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }
  role       = aws_iam_role.al2.name
  policy_arn = each.value
}
resource "aws_iam_policy" "al2" {
  name        = local.al2.subsystem_prefix
  description = local.al2.subsystem_prefix
  path        = "/"
  policy      = data.aws_iam_policy_document.al2.json
  tags = {
    Roles = local.al2.subsystem
  }
}

data "aws_iam_policy_document" "al2" {
  statement {
    sid = 1

    actions = [
      "ec2:Describe*",
      "ec2:CreateImage",
      "secretsmanager:List*",
      "secretsmanager:Get*",
      "sqs:CreateQueue",
      "sqs:DeleteMessage",
      "sqs:DeleteMessageBatch",
      "sqs:PurgeQueue",
      "sqs:SendMessage",
      "sqs:SendMessageBatch",
      "sqs:SetQueueAttributes",
      "sqs:RecievedMessage",
      "sqs:List*",
      "sqs:Get*",
      "s3:Get*",
      "s3:List*",
      "s3:Put*",
      "s3:DeleteObject",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersion",
      "s3:DeleteObjectVersionTagging",
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings",
      "ecr:PutImage",
      "sns:publish",
      "secretsmanager:GetSecretValue",
      "lambda:InvokeFunction", # NEW_EC_INFRA-116
    ]

    effect    = "Allow"
    resources = ["*"]
  }
}