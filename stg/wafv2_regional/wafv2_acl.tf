# external LB用WAF
resource "aws_wafv2_web_acl" "elb" {
  name        = "${local.resource_prefix}-external-elb"
  description = "${var.project_name} ${local.env} elb waf acl"
  scope       = "REGIONAL"
  default_action {
    allow {}
  }

  ## allow-ipset
  rule {
    name     = "${local.resource_prefix}-allow-ipset"
    priority = 10
    action {
      allow {
      }
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.elb.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.resource_prefix}-allow-ipset"
      sampled_requests_enabled   = true
    }

  }

  ## Basic認証
  rule {
    name     = "${local.resource_prefix}-basic-auth"
    priority = 20

    action {
      block {
        custom_response {
          response_code = 401
          response_header {
            name  = "www-authenticate"
            value = "Basic"
          }
        }
      }
    }

    statement {
      not_statement {
        statement {
          byte_match_statement {
            positional_constraint = "EXACTLY"
            search_string         = "Basic ZWRpb25lYzoyN2NreFhEcg=="

            field_to_match {
              single_header {
                name = "authorization"
                }
              }

            text_transformation {
              priority = 0
              type     = "NONE"
              }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${local.resource_prefix}-basic-auth"
      sampled_requests_enabled   = true
      }
    }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.resource_prefix}-basic-auth"
    sampled_requests_enabled   = true
  }
}

# association
resource "aws_wafv2_web_acl_association" "elb" {
  resource_arn = data.aws_lb.common["frontend"].arn
  web_acl_arn  = aws_wafv2_web_acl.elb.arn
}
