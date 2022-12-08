locals {
  s3_bucket = {
    server_log        = "${local.resource_prefix}-server-log"
    elb_log           = "${local.resource_prefix}-elb-log"
    ecs_exec_log      = "${local.resource_prefix}-ecs-exec-log"
    user_upload_image = "${local.resource_prefix}-user-upload-image"
    csv               = "${local.resource_prefix}-csv"
    html              = "${local.resource_prefix}-html"
    # movie             = "${local.resource_prefix}-movie"
    config            = "${local.resource_prefix}-config"
    image             = "${local.resource_prefix}-image"
    # temporary         = "${local.resource_prefix}-temporary"
    special           = "${local.resource_prefix}-special"
    mail              = "${local.resource_prefix}-mail"
    migration_tools   = "${local.resource_prefix}-migration-tools"
  }
}
resource "aws_s3_bucket" "bucket" {
  for_each = local.s3_bucket

  bucket = each.value
}
resource "aws_s3_bucket_acl" "bucket" {
  for_each = local.s3_bucket

  bucket = aws_s3_bucket.bucket[each.key].id
  acl    = "private"
}
/*
resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id = "rule-1"

    # ... other transition/expiration actions ...

    status = "Enabled"
  }
}
*/
/* bucket_policy */
resource "aws_s3_bucket_policy" "elb_log" {
  bucket = aws_s3_bucket.bucket["elb_log"].id
  policy = data.aws_iam_policy_document.elb_log.json
}
data "aws_elb_service_account" "elb_log" {}
data "aws_iam_policy_document" "elb_log" {
  statement {
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${local.resource_prefix}-elb-log/*"
    ]

    principals {
      type = "AWS"

      identifiers = [
        data.aws_elb_service_account.elb_log.arn
      ]
    }
  }
}

# special →　cloudflare に統括
/*
resource "aws_s3_bucket_website_configuration" "bucket_special" {
  bucket = aws_s3_bucket.bucket["special"].bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "special" {
  bucket = aws_s3_bucket.bucket["special"].bucket
  policy = data.aws_iam_policy_document.special.json
}

data "aws_iam_policy_document" "special" {
  statement {
    sid     = "PublicReadGetObject"
    principals {
      type = "*"
      identifiers = ["*"]
      }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${local.resource_prefix}-special/*"
    ]
    condition {
      test = "IpAddress"
      variable = "aws:SourceIp"
      values = flatten([
        local.source_ip_address_cloudflare_ip
      ])
    }
  }
}
*/

# cloudflare
resource "aws_s3_bucket_policy" "cloudflare" {
  for_each = toset([
    "special",
    # "user_upload_image",
    "image",
    "html",
    "csv",
    ])

  bucket = aws_s3_bucket.bucket[each.key].bucket
  policy = data.aws_iam_policy_document.cloudflare[each.key].json

  lifecycle {
    ignore_changes = [
      policy,
    ]
  }
}

data "aws_iam_policy_document" "cloudflare" {
  for_each = toset([
    "special",
    # "user_upload_image",
    "image",
    "html",
    "csv",
    ])
  statement {
    sid     = "PublicReadGetObject"
    principals {
      type = "*"
      identifiers = ["*"]
      }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.bucket[each.key].arn}/*"
    ]
    condition {
      test = "IpAddress"
      variable = "aws:SourceIp"
      values = flatten([
        local.source_ip_address_cloudflare_ip
      ])
    }
  }
}

# lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  for_each = toset([
    "mail",
    ])
  bucket = aws_s3_bucket.bucket[each.key].bucket

  rule {
    id = "${aws_s3_bucket.bucket[each.key].bucket}-rule"
    expiration {
      days = 30
    }
    status = "Enabled"
  }
}

# NEW_EC_INFRA-131 パブリックアクセス許可設定
resource "aws_s3_bucket_public_access_block" "private" {
  for_each = toset([
    "csv",
    ])

  bucket = aws_s3_bucket.bucket[each.key].bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  for_each = local.s3_bucket

  bucket = each.value
  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
}
