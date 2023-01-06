resource "aws_s3_bucket" "s3" {
  bucket = "monde-terraform-mig-test-s3"
  //タグの設定
  tags = {
    Name = "monde-terraform-mig-test-s3"
  }
}
