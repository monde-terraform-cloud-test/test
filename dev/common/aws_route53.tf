/*
resource "aws_route53_zone" "private" {
  name    = local.domains["private"]
  comment = "private hosted zone name"
  vpc {
    vpc_id = data.aws_vpc.vpc.id
  }
}

resource "aws_route53_zone" "env_service_domain" {
  name = "${local.env}.${local.domains["service"]}"
}

resource "aws_route53_record" "env_service_domain_ns" {
  allow_overwrite = true
  name            = "${local.env}.${local.service_domain}"
  ttl             = 300
  type            = "NS"
  zone_id         = data.aws_route53_zone.service_domain.zone_id
  # zone_id         = data.aws_route53_zone.service_domain.zone_id

  records = [
    aws_route53_zone.env_service_domain.name_servers[0],
    aws_route53_zone.env_service_domain.name_servers[1],
    aws_route53_zone.env_service_domain.name_servers[2],
    aws_route53_zone.env_service_domain.name_servers[3],
  ]
}
*/
# Route53 resolver
resource "aws_route53_resolver_endpoint" "system_cloud" {
  name      = "${local.resource_prefix}-system-cloud"
  direction = "INBOUND"

  security_group_ids = [
    aws_security_group.route53_resolver.id,
  ]
  dynamic "ip_address" {
    for_each = {
      "1a-0" = data.aws_subnet.private[0].id
      "1c-0" = data.aws_subnet.private[1].id
      # "1d-0" = data.aws_subnet.main["private_d"].id
    }
    content {
      subnet_id = ip_address.value
    }
  }

  tags = {
    Name = "${local.resource_prefix}-system-cloud"
  }

  lifecycle {
      ignore_changes = [
        ip_address,
      ]
    }
}
