resource "aws_s3_bucket" "s3" {
  bucket = "terraform-test-s3"
  //タグの設定
  tags = {
    Name = "terraform-test-s3"
  }
}
