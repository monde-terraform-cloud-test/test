locals {
  iam_user = { # NEW_EC_INFRA-86
    "edion-k.yamashita"            = aws_iam_group.edion.name
  }

/*
  operator_group_policy_attachment = {
    PowerUserAccess          = "arn:aws:iam::aws:policy/PowerUserAccess"
    AWSLambda_FullAccess     = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
    manage_own_user_with_mfa = aws_iam_policy.manage_own_user_with_mfa.arn
    manage_ecr_image         = aws_iam_policy.manage_ecr_image.arn
    allow_passrole           = aws_iam_policy.allow_passrole.arn
    operator_switch_policy   = aws_iam_policy.operator_switch_policy.arn
  }
  readonly_group_policy_attachment = {
    ReadOnlyAccess           = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    manage_own_user_with_mfa = aws_iam_policy.manage_own_user_with_mfa.arn
    allow_passrole           = aws_iam_policy.allow_passrole.arn
    readonly_switch_policy   = aws_iam_policy.readonly_switch_policy.arn
  }
*/

  edion_group_policy_attachment = { # NEW_EC_INFRA-86
    ReadOnlyAccess           = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    manage_own_user_with_mfa = aws_iam_policy.manage_own_user_with_mfa.arn
    s3_access_policy         = aws_iam_policy.s3_access_policy.arn
  }
}

resource "aws_iam_user" "operator" {
  for_each = local.iam_user

  name = each.key
  path = "/"
}

/*
resource "aws_iam_group" "operator" {
  name = "${local.resource_prefix}-operator"
  path = "/"
}
resource "aws_iam_group" "readonly" {
  name = "${local.resource_prefix}-readonly"
  path = "/"
}
*/

resource "aws_iam_group" "edion" {
  name = "${local.resource_prefix}-edion"
  path = "/"
}
resource "aws_iam_user_group_membership" "users" {
  for_each = local.iam_user
  user     = aws_iam_user.operator[each.key].name
  groups = [
    each.value,
  ]
}

/*
resource "aws_iam_group_policy_attachment" "operator" {
  for_each   = local.operator_group_policy_attachment
  group      = aws_iam_group.operator.name
  policy_arn = each.value
}
resource "aws_iam_group_policy_attachment" "readonly" {
  for_each   = local.readonly_group_policy_attachment
  group      = aws_iam_group.readonly.name
  policy_arn = each.value
}
*/
resource "aws_iam_group_policy_attachment" "edion" {
  for_each   = local.edion_group_policy_attachment
  group      = aws_iam_group.edion.name
  policy_arn = each.value
}

# MFA強制
# - ユーザーは自分のユーザー、パスワード、アクセスキー、署名証明書、SSH パブリックキー、および MFA 情報を IAM コンソールで管理できる
# - ユーザーが各自の MFA デバイスをプロビジョニングまたは管理することを許可
# - MFA を使用してユーザーがサインインした場合に限り、ユーザーが自分の MFA デバイスのみを無効化。これにより、他者がアクセスキー (MFA デバイスではない) のみを使用して MFA デバイスを無効化し、それを自分のアクセスキーと置き換えることはできない
# - ユーザーが MFA でサインインしていない場合､"Deny" と "NotAction" の組み合わせを使用して、他のすべての AWS サービスのすべてのアクションを拒否
# - サインインとパスワードの変更を許可（パスワード期限切れなどに対応）
resource "aws_iam_policy" "manage_own_user_with_mfa" {
  name        = "manage_own_user_with_mfa"
  description = "manage_own_user_with_mfa"
  policy      = data.aws_iam_policy_document.manage_own_user_with_mfa.json
}
data "aws_iam_policy_document" "manage_own_user_with_mfa" {
  statement {
    sid    = "AllowAllUsersToListAccounts"
    effect = "Allow"
    actions = [
      "iam:ListAccountAliases",
      "iam:ListUsers",
      "iam:ListVirtualMFADevices",
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "AllowIndividualUserToSeeAndManageOnlyTheirOwnAccountInformation"
    effect = "Allow"
    actions = [
      "iam:ChangePassword",
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
      "iam:DeleteAccessKey",
      "iam:DeleteLoginProfile",
      "iam:GetLoginProfile",
      "iam:ListAccessKeys",
      "iam:UpdateAccessKey",
      "iam:UpdateLoginProfile",
      "iam:ListSigningCertificates",
      "iam:DeleteSigningCertificate",
      "iam:UpdateSigningCertificate",
      "iam:UploadSigningCertificate",
      "iam:ListSSHPublicKeys",
      "iam:GetSSHPublicKey",
      "iam:DeleteSSHPublicKey",
      "iam:UpdateSSHPublicKey",
      "iam:UploadSSHPublicKey"
    ]
    resources = [
      "arn:aws:iam::*:user/&{aws:username}"
    ]
  }
  statement {
    sid    = "AllowIndividualUserToListOnlyTheirOwnMFA"
    effect = "Allow"
    actions = [
      "iam:ListMFADevices"
    ]
    resources = [
      "arn:aws:iam::*:mfa/*",
      "arn:aws:iam::*:user/&{aws:username}"
    ]
  }
  statement {
    sid    = "AllowIndividualUserToManageTheirOwnMFA"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice"
    ]
    resources = [
      "arn:aws:iam::*:mfa/&{aws:username}",
      "arn:aws:iam::*:user/&{aws:username}"
    ]
  }
  statement {
    sid    = "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA"
    effect = "Allow"
    actions = [
      "iam:DeactivateMFADevice"
    ]
    resources = [
      "arn:aws:iam::*:mfa/&{aws:username}",
      "arn:aws:iam::*:user/&{aws:username}"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
  statement {
    sid    = "BlockMostAccessUnlessSignedInWithMFA"
    effect = "Deny"
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:ListVirtualMFADevices",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
      "iam:ListAccountAliases",
      "iam:ListUsers",
      "iam:ListSSHPublicKeys",
      "iam:ListAccessKeys",
      "iam:ListServiceSpecificCredentials",
      "iam:ListMFADevices",
      "iam:GetAccountSummary",
      "sts:GetSessionToken",
      "iam:CreateLoginProfile",
      "iam:ChangePassword"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

/*
resource "aws_iam_policy" "manage_ecr_image" {
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
}
*/

/*
# Switch policy
resource "aws_iam_policy" "operator_switch_policy" {
  name        = "operator_switch_policy"
  description = "operator_switch_policy"
  policy      = data.aws_iam_policy_document.operator_switch_policy.json
}
data "aws_iam_policy_document" "operator_switch_policy" {
  statement {
    sid    = "OperatorSwitchPolicy"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::681446296757:role/edion-ecsite-stg-operator-switch-role",
      "arn:aws:iam::030139384494:role/edion-ecsite-prd-operator-switch-role",
    ]
  }
}
resource "aws_iam_policy" "readonly_switch_policy" {
  name        = "readonly_switch_policy"
  description = "readonly_switch_policy"
  policy      = data.aws_iam_policy_document.readonly_switch_policy.json
}
data "aws_iam_policy_document" "readonly_switch_policy" {
  statement {
    sid    = "ReadonlySwitchPolicy"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::681446296757:role/edion-ecsite-stg-readonly-switch-role",
      "arn:aws:iam::030139384494:role/edion-ecsite-prd-readonly-switch-role",
    ]
  }
}
*/

# s3検証用ポリシー　NEW_EC_INFRA-86
resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3_access_policy"
  description = "s3_access_policy"
  policy      = data.aws_iam_policy_document.s3_access_policy.json
}
data "aws_iam_policy_document" "s3_access_policy" {
  statement {
    sid    = "ListObjectsInBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      data.aws_s3_bucket.common["special"].arn,
    ]
  }
  statement {
    sid    = "ObjectControlAction"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${data.aws_s3_bucket.common["special"].arn}/*",
    ]
  }
}