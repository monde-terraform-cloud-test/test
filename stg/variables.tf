variable "project_name" {
  type    = string
  default = "edion"
}
variable "service_name" {
  type    = string
  default = "ecsite"
}

locals {
  env                     = "stg"
  env_long                = "staging"
  resource_prefix         = "${var.project_name}-${var.service_name}-${local.env}"
  service_domain          = ""
  vpc_cidr                = "10.125.0.0/16" # NEW_EC_INFRA-17
  edion_system_cloud_cidr = "10.117.0.0/16" # NEW_EC_INFRA-3 transit gateway接続先
  tgw_cidr                = "10.67.0.0/16"


  # NEW_EC_INFRA-71
  edion_on_premise_01_cidr = "10.0.0.0/8"
  edion_on_premise_02_cidr = "172.16.0.0/12"
  edion_on_premise_03_cidr = "192.168.0.0/16"
  edion_on_premise_04_cidr = "10.120.31.0/24"
  edion_on_premise_05_cidr = "10.68.112.0/24"
  edion_on_premise_06_cidr = "10.68.201.0/24"
  edion_on_premise_07_cidr = "10.67.0.0/16"
  edion_on_premise_08_cidr = "172.26.201.0/24" # NEW_EC_INFRA-160 エディオン JR尼崎駅店５F 開発ルーム
  edion_on_premise_09_cidr = "172.26.203.0/24" # NEW_EC_INFRA-160 エディオン アネックスビル 開発ルーム

  availability_zones = {
    0 = "${data.aws_region.current.name}a"
    1 = "${data.aws_region.current.name}c"
    # 2 = "${data.aws_region.current.name}d"
  }
  /* IP情報 */
  source_ip_address_nat_gateway = [
    "${data.aws_nat_gateway.main["public_a"].public_ip}/32",
  ]

  source_ip_address_hampstead = [
    "150.249.199.195/32", # 品川拠点 NEW_EC_INFRA-1
  ]

  source_ip_address_edion_PC_Head_Store = [ # NEW_EC_INFRA-44
    "208.127.162.8/32",                     # PC用	Japan Central	NIC	本部・店舗
    "34.98.170.39/32",                      # PC用	Japan South	NIC	本部・店舗
    "34.98.169.182/32",                     # PC用	Japan South	アネックス、JR尼崎駅店	店舗
    "34.98.169.183/32",                     # PC用	Japan South	NIC	本部・店舗
    "208.127.162.205/32",                   # PC用	Japan South	尼崎（情シス） 海田店	本部
    "137.83.213.235/32",                    # PC用	Japan South	中之島本社	本部
    "137.83.213.236/32",                    # PC用	Japan South	中之島本社	本部
    "137.83.213.220/32",                    # PC用	Japan South	尼崎（ELSほか）	本部
    "137.83.215.87/32",                     # PC用	Japan South	NIC	本部・店舗
    "137.83.215.86/32",                     # PC用	Japan South	NIC	本部・店舗
  ]
  source_ip_address_edion_PC_GP = [ # NEW_EC_INFRA-44
    "34.98.173.200/32",             # PC用	Japan Central	GP	GP
    "34.98.161.90/32",              # PC用	Japan Central	GP	GP
    "134.238.5.117/32",             # PC用	Japan Central	GP	GP
    "134.238.6.178/32",             # PC用	Japan Central	GP	GP
    "34.98.170.32/32",              # PC用	Japan South	GP	GP
    "34.100.104.182/32",            # PC用	Japan South	GP	GP
    "134.238.3.29/32",              # PC用	Japan South	GP	GP
    "134.238.3.105/32",             # PC用	Japan South	GP	GP
    "134.238.3.107/32",             # PC用	Japan South	GP	GP
    "134.238.3.28/32",              # PC用	Japan South	GP	GP
    "34.98.172.113/32",             # PC用	Japan South	GP	GP
    "66.159.200.62/32",             # PC用	Japan South	GP	GP
    "208.127.162.33/32",            # PC用	Japan South	GP	GP
    "34.98.172.114/32",             # PC用	Japan South	GP	GP
    "208.127.162.44/32",            # PC用	Japan South	GP	GP
    "208.127.162.54/32",            # PC用	Japan South	GP	GP
    "208.127.162.3/32",             # PC用	Japan South	GP	GP
    "208.127.162.53/32",            # PC用	Japan South	GP	GP
    "208.127.162.51/32",            # PC用	Japan South	GP	GP
    "208.127.162.49/32",            # PC用	Japan South	GP	GP
    "208.127.162.34/32",            # PC用	Japan South	GP	GP
    "34.98.161.89/32",              # PC用	Japan South	GP	GP
    "208.127.84.23/32",             # PC用	US West	GP	GP
    "208.127.84.230/32",            # PC用	US West	GP	GP
  ]
  source_ip_address_edion_Mobile_GP = [ # NEW_EC_INFRA-44
    "34.98.173.126/32",                 # モバイル用	Japan Central	GP	GP
    "34.98.161.95/32",                  # モバイル用	Japan Central	GP	GP
    "134.238.6.160/32",                 # モバイル用	Japan Central	GP	GP
    "134.238.5.119/32",                 # モバイル用	Japan Central	GP	GP
    "34.98.169.184/32",                 # モバイル用	Japan South	GP	GP
    "34.100.104.184/32",                # モバイル用	Japan South	GP	GP
    "34.98.170.3/32",                   # モバイル用	Japan South	GP	GP
    "34.100.104.183/32",                # モバイル用	Japan South	GP	GP
    "34.98.161.92/32",                  # モバイル用	Japan South	GP	GP
    "34.98.172.115/32",                 # モバイル用	Japan South	GP	GP
    "208.127.84.231/32",                # モバイル用	US West	GP	GP
    "208.127.84.232/32",                # モバイル用	US West	GP	GP
  ]
  source_ip_address_edion_test_client = [ # NEW_EC-568
    "153.156.194.215/32"
  ]


  source_ip_address_edion_intarnal_ip_01 = [ # NEW_EC_INFRA-85
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ]

  source_ip_address_edion_intarnal_ip_02 = [ # NEW_EC_INFRA-85
    "10.68.201.3/32",
    "10.120.31.43/32",
    "10.120.31.51/32",
    "10.120.31.52/32",
    "10.68.112.0/24",
  ]
  
  source_ip_address_cloudflare_ip = [ # NEW_EC_INFRA-111
        "103.21.244.0/22",
        "103.22.200.0/22",
        "103.31.4.0/22",
        "104.16.0.0/13",
        "104.24.0.0/14",
        "108.162.192.0/18",
        "131.0.72.0/22",
        "141.101.64.0/18",
        "162.158.0.0/15",
        "172.64.0.0/13",
        "173.245.48.0/20",
        "188.114.96.0/20",
        "190.93.240.0/20",
        "197.234.240.0/22",
        "198.41.128.0/17",
  ]

  source_ip_address_edion_Exchange_Dataspider = [ # NEW_EC_INFRA-103
    "3.115.157.196/32"
  ]

  domains = {
    #private = "${var.project_name}.${local.env}.local"
    private = "${local.env}.${var.project_name}sys1.internal"
    service = "edion.com"
  }

  /* codepipeline */
  # [Notification concepts \- Developer Tools console](https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#concepts-api)
  codepipeline_event_type_ids = [
    # Action execution
    #"codepipeline-pipeline-action-execution-succeeded",
    #"codepipeline-pipeline-action-execution-failed",
    #"codepipeline-pipeline-action-execution-canceled",
    #"codepipeline-pipeline-action-execution-started",
    # Stage execution",
    #"codepipeline-pipeline-stage-execution-started",
    #"codepipeline-pipeline-stage-execution-succeeded",
    #"codepipeline-pipeline-stage-execution-resumed",
    #"codepipeline-pipeline-stage-execution-canceled",
    #"codepipeline-pipeline-stage-execution-failed",
    # Pipeline execution",
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-canceled",
    #"codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-resumed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-pipeline-execution-superseded",
    # Manual approval",
    "codepipeline-pipeline-manual-approval-failed",
    "codepipeline-pipeline-manual-approval-needed",
    "codepipeline-pipeline-manual-approval-succeeded",
  ]
}

variable "transit_gateway" {
  type = map(any)
  default = {
    "system_cloud_gateway_id"             = "tgw-xxxxxxxxxxxxxxxx"
    "system_cloud_gateway_route_table_id" = "tgw-rtb-xxxxxxxxxxxxxxxx"
  }
}