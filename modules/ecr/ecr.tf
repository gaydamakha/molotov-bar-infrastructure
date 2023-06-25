resource "aws_ecr_repository" "repositories" {
  for_each = var.registry

  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecr_lifecycle_policy" "repositories_lc_policies" {
  for_each = var.registry

  repository = aws_ecr_repository.repositories[each.key].name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 10 images for dev",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["dev-"],
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Keep last 10 images for prod",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["prod-"],
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "repository_policy_document" {
  statement {
    sid    = "AllowPull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [for account_id in var.account_ids : "arn:aws:iam::${account_id}:root"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
  }
}

resource "aws_ecr_repository_policy" "repository_policy" {
  for_each = var.registry

  repository = aws_ecr_repository.repositories[each.key].name
  policy     = data.aws_iam_policy_document.repository_policy_document.json

  lifecycle {
    prevent_destroy = true
  }
}
