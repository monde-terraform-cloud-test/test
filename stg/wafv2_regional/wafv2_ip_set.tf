resource "aws_wafv2_ip_set" "elb" {
  name               = "${local.resource_prefix}-external-elb"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = flatten(
    [
      local.source_ip_address_hampstead,
      local.source_ip_address_edion_PC_Head_Store,
      local.source_ip_address_edion_PC_GP,
      local.source_ip_address_edion_Mobile_GP,
      local.source_ip_address_edion_test_client,
      local.source_ip_address_edion_Exchange_Dataspider,
      local.source_ip_address_cloudflare_ip,
    ]
  )
}
