################################################################################
# Target Group
################################################################################
resource "aws_lb_target_group" "alb_role" {
  depends_on = [aws_lb.alb_role]

  name             = local.role_prefix
  vpc_id           = data.aws_vpc.vpc.id
  port             = 8080
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  target_type      = "ip"

  deregistration_delay          = 60
  slow_start                    = 0
  load_balancing_algorithm_type = "round_robin"

  health_check {
    interval            = 10
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "${local.role_prefix}"
  }
}
################################################################################
# ALB
################################################################################
resource "aws_lb" "alb_role" {
  name = local.role_prefix

  load_balancer_type = "application"
  internal           = false
  security_groups = [
    aws_security_group.alb_role.id,
  ]
  subnets = [
    data.aws_subnet.main["public_a"].id,
    data.aws_subnet.main["public_c"].id,
  ]

  idle_timeout                     = 180
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false
  enable_http2                     = true
  drop_invalid_header_fields       = false
  #[Support waf fail open attribute for ALB · Issue \#16372 · hashicorp/terraform\-provider\-aws · GitHub](https://github.com/hashicorp/terraform-provider-aws/issues/16372)
  #enable_waf_fail_open = true

  access_logs {
    enabled = true
    bucket  = data.aws_s3_bucket.common["elb_log"].id
    prefix  = local.role_prefix
  }

  tags = {
    Name = local.role_prefix
  }
}
################################################################################
# ELB Listener
################################################################################
resource "aws_lb_listener" "alb_role" {
  depends_on = [
    aws_lb.alb_role,
  ]

  lifecycle {
    ignore_changes = [
      default_action[0]
    ]
  }

  load_balancer_arn = aws_lb.alb_role.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.service_domain_cert_ap_northeast_1.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{ \"result\": true, \"request_id\": \"NoContent\" }"
      status_code  = "200"
    }
  }
}
resource "aws_lb_listener_rule" "alb_role_https" {
  listener_arn = aws_lb_listener.alb_role.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_role.arn
  }

  condition {
    path_pattern {
      values = [
        "/*",
      ]
    }
  }
  lifecycle {
    ignore_changes = [
      # action[0].forward[0].target_group,
    ]
  }
}

/* ドメイン・証明書決定前の動確用 */
resource "aws_lb_listener" "alb_role_http_tmp" {
  depends_on = [
    aws_lb.alb_role,
  ]

  lifecycle {
    ignore_changes = [
      #default_action[0]
    ]
  }

  load_balancer_arn = aws_lb.alb_role.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{ \"result\": true, \"request_id\": \"NoContent\" }"
      status_code  = "200"
    }
  }
}
resource "aws_lb_listener_rule" "alb_role_http_tmp" {
  listener_arn = aws_lb_listener.alb_role_http_tmp.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_role.arn
  }

  condition {
    path_pattern {
      values = [
        "/*",
      ]
    }
  }
  lifecycle {
    ignore_changes = [
      # action[0].forward[0].target_group,
    ]
  }
}