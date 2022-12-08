
/*
resource "aws_acm_certificate" "wild_ap_northeast_1" {
  domain_name               = "*.${local.domains.service}"
  #subject_alternative_names = ["${local.domains.service}"]
  validation_method         = "DNS"
}
output "acm_domain_validation_options_wild_ap_northeast_1" {
  value = aws_acm_certificate.wild_ap_northeast_1.domain_validation_options
}
*/
/* レコード登録後に追加予定
resource aws_acm_certificate_validation wild_ap_northeast_1 {
  for_each = {
    for dvo in aws_acm_certificate.wild_ap_northeast_1.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  certificate_arn = aws_acm_certificate.wild_ap_northeast_1.arn
  validation_record_fqdns = [each.value.name]
}
*/