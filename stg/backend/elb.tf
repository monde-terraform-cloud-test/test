################################################################################
# Target Group
################################################################################
resource "aws_lb_target_group" "alb_role_internal" {
  depends_on = [aws_lb.alb_role_internal]

  name   = "${local.role_prefix}-i"
  vpc_id = data.aws_vpc.vpc.id
  port             = 8080
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  target_type      = "ip"

  deregistration_delay          = 60
  slow_start                    = 0
  load_balancing_algorithm_type = "round_robin"

  health_check {
    interval            = 10
    path                = "/health.php"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "${local.role_prefix}-i"
  }
}
################################################################################
# ALB
################################################################################
resource "aws_lb" "alb_role_internal" {
  name = "${local.role_prefix}-i"

  load_balancer_type = "application"
  internal           = true
  security_groups = [
    aws_security_group.alb_role.id,
  ]
  subnets = [
    data.aws_subnet.main["private_a"].id,
    data.aws_subnet.main["private_c"].id,
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
    prefix  = "${local.role_prefix}-i"
  }

  tags = {
    Name = "${local.role_prefix}-i"
  }
}
################################################################################
# ELB Listener
################################################################################
resource "aws_lb_listener" "alb_role_internal_http" {
  depends_on = [
    aws_lb.alb_role_internal,
  ]

  lifecycle {
    ignore_changes = [
      #default_action[0]
    ]
  }

  load_balancer_arn = aws_lb.alb_role_internal.arn
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
resource "aws_lb_listener_rule" "alb_role_internal_http" {
  listener_arn = aws_lb_listener.alb_role_internal_http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_role_internal.arn
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