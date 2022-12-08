variable "role" {
  default = "batch"
}

locals {
  role_prefix = "${local.resource_prefix}-${var.role}"
}
