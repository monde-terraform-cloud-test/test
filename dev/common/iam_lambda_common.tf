# NEW_EC_INFRA-93
resource "aws_iam_role" "lambda_common" {
  name               = "${local.resource_prefix}-lambda-common"
  assume_role_policy = data.aws_iam_policy_document.assumerole["lambda"].json

  tags = {
    Name = "${local.resource_prefix}-lambda-common"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_common" {
  for_each = {
    AWSLambdaBasicExecutionRole    = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    AmazonSSMMaintenanceWindowRole = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
  }
  role       = aws_iam_role.lambda_common.name
  policy_arn = each.value
}
