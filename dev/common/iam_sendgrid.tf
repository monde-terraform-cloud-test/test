# NEW_EC_INFRA-153
## AWS Lambda関数新規作成で「基本的な Lambda アクセス権限で新しいロールを作成する」で作成されるIAMロール
resource "aws_iam_role" "sendgrid_lambda" {
  name               = "${local.resource_prefix}-sendgrid-lambda"
  assume_role_policy = data.aws_iam_policy_document.assumerole["lambda"].json

  tags = {
    Name = "${local.resource_prefix}-sendgrid-lambda"
  }
}
resource "aws_iam_role_policy_attachment" "sendgrid_lambda" {
  for_each = {
    sendgrid_lambda    = aws_iam_policy.sendgrid_lambda.arn
  }
  role       = aws_iam_role.sendgrid_lambda.name
  policy_arn = each.value
}
resource "aws_iam_policy" "sendgrid_lambda" {
  name        = "${local.resource_prefix}-sendgrid-lambda"
  description = "${local.resource_prefix}-sendgrid-lambda"
  path        = "/"
  policy      = data.aws_iam_policy_document.sendgrid_lambda.json
}
data "aws_iam_policy_document" "sendgrid_lambda" {
  statement {
    sid    = "CloudWatchLogsPolicy01"
    effect = "Allow"
    actions = [
		"logs:CreateLogStream",
		"logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*",
    ]
  }
  statement {
    sid    = "CloudWatchLogsPolicy02"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*",
    ]
  }
  statement {
    sid = "S3Policy01"
    actions = [
      "s3:List*",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "S3Policy02"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
    ]
    effect    = "Allow"
    resources = [
      "${data.aws_s3_bucket.common["mail"].arn}/*"
      ]
  }
}

## AWS GlueでCrawlerを作成する場合に「Create new IAM role」で作成されるIAMロール
resource "aws_iam_role" "sendgrid_glue" {
  name               = "${local.resource_prefix}-sendgrid-glue"
  assume_role_policy = data.aws_iam_policy_document.assumerole["glue"].json

  tags = {
    Name = "${local.resource_prefix}-sendgrid-glue"
  }
}
resource "aws_iam_role_policy_attachment" "sendgrid_glue" {
  for_each = {
	AWSGlueServiceRole = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
	AmazonS3FullAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
	# sendgrid_glue    = aws_iam_policy.sendgrid_glue.arn
  }
  role       = aws_iam_role.sendgrid_glue.name
  policy_arn = each.value
}
