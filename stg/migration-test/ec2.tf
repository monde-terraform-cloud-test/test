locals {
  migration_test = {
    subsystem        = "migration-test"
    subsystem_prefix = "${local.resource_prefix}-migration-test"

    ami_id           = data.aws_ami.amazonlinux2022_latest.id
    instance_type    = "t3.micro"
    ebs_optimized    = false
    root_volume_type = "gp3"
    root_volume_size = 50
  }

  key_name = local.migration_test.subsystem_prefix

  ec2_for_each = {
    "1c-0" = data.aws_subnet.main["public_c"].id
    # "1a-0" = data.aws_subnet.main["private_a"].id
    # "1c-0" = data.aws_subnet.main["private_c"].id
    # "1d-0" = data.aws_subnet.main["private_d"].id
  }
}

data "aws_ami" "amazonlinux2022_latest" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2022-ami-2022.0.20220315.0-kernel-5.15-x86_64"]
  }
}

## EC2
resource "aws_instance" "migration_test" {
  for_each = local.ec2_for_each

  ami                  = local.migration_test.ami_id
  instance_type        = local.migration_test.instance_type
  key_name             = local.key_name
  iam_instance_profile = aws_iam_instance_profile.migration_test.name
  subnet_id            = each.value
  ebs_optimized        = local.migration_test.ebs_optimized
  vpc_security_group_ids = [
    aws_security_group.common_sg.id,
  ]
  associate_public_ip_address = true
  root_block_device {
    volume_type = local.migration_test.root_volume_type
    volume_size = local.migration_test.root_volume_size
  }
  tags = {
    Name = "${local.migration_test.subsystem_prefix}"
    # Name         = "${local.migration_test.subsystem_prefix}-${each.key}"
    Roles = local.migration_test.subsystem
  }
  volume_tags = {
    Name = local.migration_test.subsystem_prefix
  }
  user_data = <<EOF
setenforce 0
dnf -y update
sed -i '1s/^/PubkeyAcceptedAlgorithms=+ssh-rsa\n/' /etc/ssh/sshd_config
systemctl stop sshd.service
systemctl start sshd.service
timedatectl set-timezone Asia/Tokyo
localectl set-locale LANG=ja_JP.utf8
dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
dnf install -y https://s3.ap-northeast-1.amazonaws.com/amazoncloudwatch-agent-ap-northeast-1/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
sed -i -e "s/enforcing=1/enforcing=0/g" /etc/default/grub
grub2-mkconfig -o /etc/grub2.cfg
EOF
}

resource "aws_iam_instance_profile" "migration_test" {
  name = local.migration_test.subsystem_prefix
  role = aws_iam_role.migration_test.name
  tags = {
    Roles = local.migration_test.subsystem
  }
}
resource "aws_iam_role" "migration_test" {
  name               = local.migration_test.subsystem_prefix
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assumerole["ec2"].json
  tags = {
    Roles = local.migration_test.subsystem
  }
}
/* aws_iam_role_policy_attachment
--target 'aws_iam_role_policy_attachment.migration_test["SSMManagedInstanceCore"]'
--target 'aws_iam_role_policy_attachment.migration_test["migration_test"]'
*/
resource "aws_iam_role_policy_attachment" "migration_test" {
  for_each = {
    SSMManagedInstanceCore     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    migration_test                       = aws_iam_policy.migration_test.arn
  }
  role       = aws_iam_role.migration_test.name
  policy_arn = each.value
}
resource "aws_iam_policy" "migration_test" {
  name        = local.migration_test.subsystem_prefix
  description = local.migration_test.subsystem_prefix
  path        = "/"
  policy      = data.aws_iam_policy_document.migration_test.json
  tags = {
    Roles = local.migration_test.subsystem
  }
}

data "aws_iam_policy_document" "migration_test" {
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
    ]

    effect    = "Allow"
    resources = ["*"]
  }
}