locals {
  s3_bucket = {
    migration_test = "${local.resource_prefix}-migration-test"
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