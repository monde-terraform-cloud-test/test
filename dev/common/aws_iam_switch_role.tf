## devアカウントからのswitch role用iam
locals {
  operator_group_policy_attachment = {
    PowerUserAccess      = "arn:aws:iam::aws:policy/PowerUserAccess"
    AWSLambda_FullAccess = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
    manage_ecr_image     = "arn:aws:iam::846364808165:policy/manage_ecr_image"
    #manage_ecr_image     = aws_iam_policy.manage_ecr_image.arn
    allow_passrole       = "arn:aws:iam::846364808165:policy/allow_passrole"
    #allow_passrole       = aws_iam_policy.allow_passrole.arn
    deny_payment         = aws_iam_policy.deny_payment.arn
  }
  readonly_group_policy_attachment = {
    ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    allow_passrole       = "arn:aws:iam::846364808165:policy/allow_passrole"
    #allow_passrole       = aws_iam_policy.allow_passrole.arn
    deny_payment   = aws_iam_policy.deny_payment.arn
  }
}

resource "aws_iam_role" "operator_switch_role" {
  name = "${local.resource_prefix}-operator-switch-role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              "arn:aws:iam::846364808165:user/operator-user-01",
              "arn:aws:iam::846364808165:user/operator-user-02",
              "arn:aws:iam::846364808165:user/operator-user-03",
              "arn:aws:iam::846364808165:user/operator-user-04",
              "arn:aws:iam::846364808165:user/operator-user-05",
              "arn:aws:iam::846364808165:user/operator-user-06",
              "arn:aws:iam::846364808165:user/operator-user-07",
              "arn:aws:iam::846364808165:user/operator-user-08",
              "arn:aws:iam::846364808165:user/operator-user-09",
              "arn:aws:iam::846364808165:user/operator-user-10",
              "arn:aws:iam::846364808165:user/operator-user-test01",
            ]
          },
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  tags = {
    Name = "wod-prod-switch-role"
  }
}
resource "aws_iam_role" "readonly_switch_role" {
  name = "${local.resource_prefix}-readonly-switch-role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              # "arn:aws:iam::846364808165:user/readonly-user-01",
              "arn:aws:iam::846364808165:user/readonly-user-test01",
            ]
          },
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  tags = {
    Name = "wod-prod-switch-role"
  }
}
resource "aws_iam_role_policy_attachment" "operator_switch_role" {
  for_each   = local.operator_group_policy_attachment
  role       = aws_iam_role.operator_switch_role.name
  policy_arn = each.value
}
resource "aws_iam_role_policy_attachment" "readonly_switch_role" {
  for_each   = local.readonly_group_policy_attachment
  role       = aws_iam_role.readonly_switch_role.name
  policy_arn = each.value
}
/*resource "aws_iam_policy" "manage_ecr_image" {
  name        = "manage_ecr_image"
  description = "manage_ecr_image"
  policy      = data.aws_iam_policy_document.manage_ecr_image.json
}
data "aws_iam_policy_document" "manage_ecr_image" {
  statement {
    sid    = "AllowManageECR"
    effect = "Allow"
    actions = [
      "ecr:UploadLayerPart",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:CompleteLayerUpload",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = [
      "*"
    ]
  }
}
resource "aws_iam_policy" "allow_passrole" {
  name        = "allow_passrole"
  description = "allow_passrole"
  policy      = data.aws_iam_policy_document.allow_passrole.json
}
data "aws_iam_policy_document" "allow_passrole" {
  statement {
    sid    = "AllowPassrole"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:ListRoles",
      "iam:PassRole"
    ]
    resources = [
      "*"
    ]
  }
}*/

resource "aws_iam_policy" "deny_payment" {
  name        = "deny_payment"
  description = "deny_payment"
  policy      = data.aws_iam_policy_document.deny_payment.json
}
data "aws_iam_policy_document" "deny_payment" {
  statement {
    sid    = "DenyPayment"
    effect = "Deny"
    actions = [
      "organizations:*",
      "aws-portal:ViewPaymentMethods",
      "aws-portal:ModifyAccount",
      "aws-portal:ViewAccount",
      "aws-portal:ModifyPaymentMethods",
      "support:*"
    ]
    resources = [
      "*"
    ]
  }
}