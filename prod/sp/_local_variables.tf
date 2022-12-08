variable "role" {
  default = "sp"
}

locals {
  role_prefix = "${local.resource_prefix}-${var.role}"
}
