variable "role" {
  default = "backend"
}

locals {
  role_prefix = "${local.resource_prefix}-${var.role}"
}
