locals {
  computed_repository_dir = "../../../apps/"
  computed_repository_names = [
    for d in distinct([
      for f in flatten(fileset(path.root, "${local.computed_repository_dir}*/*")) :
      dirname(f)
    ]) :
    "interop-infra-${replace(d, local.computed_repository_dir, "")}"
  ]
  custom_repository_names = []
}

resource "aws_ecr_repository" "app" {
  for_each = toset(concat(local.computed_repository_names, local.custom_repository_names))

  image_tag_mutability = contains(["dev"], var.env) ? "MUTABLE" : "IMMUTABLE"
  name                 = each.key
}

resource "aws_ecr_lifecycle_policy" "app" {
  for_each = { for repo in aws_ecr_repository.app : repo.name => repo if var.env == "dev" }

  repository = each.value.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
