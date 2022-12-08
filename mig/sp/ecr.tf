resource "aws_ecr_repository" "role" {
  name                 = local.role_prefix
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = local.role_prefix
  }
}

output "role_container_registry_url" {
  value = aws_ecr_repository.role.repository_url
}
