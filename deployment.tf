data "aws_caller_identity" "current" {}
resource "helm_release" "challenge" {

  name      = "challenge"
  chart     = "${path.module}/challenge/helm/mywebapp"
  namespace = "default"
  timeout   = 60
  
}

resource "aws_ecr_repository" "challenge" {
  name                 = "challenge"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_repository_policy" "challenge" {
  repository = aws_ecr_repository.challenge.name
  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "AccountEcr",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                  "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
                ]
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:ListImages"
            ]
        }
    ]
}
EOF
}