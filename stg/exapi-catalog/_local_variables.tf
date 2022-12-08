variable "role" {
  default = "exapi-catalog"
}

locals {
  role_prefix = "${local.resource_prefix}-${var.role}"
}
