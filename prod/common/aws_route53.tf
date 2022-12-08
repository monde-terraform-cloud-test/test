# Route53 
## プライベートホストゾーンをprd環境で統括管理とするため、prd/stg/dev環境をそれぞれ記載

resource "aws_route53_zone" "private" {
  name    = local.domains["private"]
  comment = "private hosted zone name"
  vpc {
    vpc_id = data.aws_vpc.vpc.id
  }
  vpc {
   vpc_id     = "vpc-00257fe238566971e"
   vpc_region = "ap-northeast-1"
      }
  vpc {
   vpc_id     = "vpc-0f8f1ff850bef7f97"
   vpc_region = "ap-northeast-1"
      }
}

/*
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
      "1a-0" = data.aws_subnet.main["private_a"].id
      "1c-0" = data.aws_subnet.main["private_c"].id
      # "1d-0" = data.aws_subnet.main["private_d"].id
    }
    content {
      subnet_id = ip_address.value
    }
  }

  tags = {
    Name = "${local.resource_prefix}-system-cloud"
  }
}

## outbound
resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "${local.resource_prefix}-outbound"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.route53_outbound.id,
  ]
  dynamic "ip_address" {
    for_each = {
      "1a-0" = data.aws_subnet.main["private_a"].id
      "1c-0" = data.aws_subnet.main["private_c"].id
      # "1d-0" = data.aws_subnet.main["private_d"].id
    }
    content {
      subnet_id = ip_address.value
    }
  }

  tags = {
    Name = "${local.resource_prefix}-outbound"
  }
}

resource "aws_route53_resolver_rule" "outbound" {
  domain_name          = "edion.internal"
  name                 = "${local.resource_prefix}-outbound"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  target_ip {
    ip = "10.70.222.1"
  }

    target_ip {
    ip = "10.68.222.1"
  }

  tags = {
    Name = "${local.resource_prefix}-outbound"
  }
}

resource "aws_route53_resolver_rule_association" "outbound" {
  resolver_rule_id = aws_route53_resolver_rule.outbound.id
  vpc_id           = data.aws_vpc.vpc.id
  name             = "${local.resource_prefix}-outbound"
}

# recode
## prd
### ALB
resource "aws_route53_record" "internal_alb_backend_prd" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-bke101-prd.${local.domains["private"]}"
   type         = "A"
  alias {
    name                   = "internal-edion-ecsite-prd-backend-i-307567753.ap-northeast-1.elb.amazonaws.com"
    zone_id                = "Z14GRHDCWA56QT"
    evaluate_target_health = false
  }
}

### ElasiCache
resource "aws_route53_record" "elasicache_primary_prd" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-red101-prd.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-prd-redis-01.bbthym.ng.0001.apne1.cache.amazonaws.com"]
}

resource "aws_route53_record" "elasicache_reader_prd" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-red102-prd.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-prd-redis-01-ro.bbthym.ng.0001.apne1.cache.amazonaws.com"]
}

### RDS
resource "aws_route53_record" "rds_writer_prd" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-psq101-prd.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-prd-db-01.cluster-cvpi7g8yuya3.ap-northeast-1.rds.amazonaws.com"]
}

resource "aws_route53_record" "rds_reader_prd" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-psq102-prd.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-prd-db-01.cluster-ro-cvpi7g8yuya3.ap-northeast-1.rds.amazonaws.com"]
}


## stg
### ALB
resource "aws_route53_record" "internal_alb_backend_stg" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-bke102-stg.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["internal-edion-ecsite-stg-backend-i-1064180239.ap-northeast-1.elb.amazonaws.com"]
}

### ElasiCache
resource "aws_route53_record" "elasicache_primary_stg" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-red103-stg.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-stg-redis-01.rczhxl.ng.0001.apne1.cache.amazonaws.com"]
}

resource "aws_route53_record" "elasicache_reader_stg" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-red104-stg.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-stg-redis-01-ro.rczhxl.ng.0001.apne1.cache.amazonaws.com"]
}

### RDS
resource "aws_route53_record" "rds_writer_stg" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-psq103-stg.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-stg-db-01.cluster-cjp2uxsfjkhv.ap-northeast-1.rds.amazonaws.com"]
}

resource "aws_route53_record" "rds_reader_stg" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-psq104-stg.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-stg-db-01.cluster-ro-cjp2uxsfjkhv.ap-northeast-1.rds.amazonaws.com"]
}


## dev
### ALB
resource "aws_route53_record" "internal_alb_backend_dev" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-bke103-dev.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["internal-edion-ecsite-dev-backend-i-659754612.ap-northeast-1.elb.amazonaws.com"]
}

### ElasiCache
resource "aws_route53_record" "elasicache_primary_dev" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-red105-dev.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-dev-redis-01.btze3k.ng.0001.apne1.cache.amazonaws.com"]
}

resource "aws_route53_record" "elasicache_reader_dev" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-red106-dev.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-dev-redis-01-ro.btze3k.ng.0001.apne1.cache.amazonaws.com"]
}

### RDS
resource "aws_route53_record" "rds_writer_dev" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-psq105-dev.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-dev-db-01.cluster-ctxchxyczx4r.ap-northeast-1.rds.amazonaws.com"]
}

resource "aws_route53_record" "rds_reader_dev" {
   zone_id      = aws_route53_zone.private.zone_id
   name         = "ec-psq106-dev.${local.domains["private"]}"
   type         = "CNAME"
   ttl          = 300
   records      = ["edion-ecsite-dev-db-01.cluster-ro-ctxchxyczx4r.ap-northeast-1.rds.amazonaws.com"]
}
