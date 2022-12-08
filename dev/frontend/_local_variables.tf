variable "role" {
  default = "frontend"
}

locals {
  role_prefix = "${local.resource_prefix}-${var.role}"
}
