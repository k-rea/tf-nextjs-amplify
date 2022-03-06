locals {
  profile       = "my_profile"
  region        = "ap-northeast-1"
  app_name      = "app_name"
  domain        = "my_domain"
  domain_prefix = "app-name"
}

provider "aws" {
  region  = local.region
  profile = local.profile
}

resource "aws_codecommit_repository" "static_site_amplify" {
  repository_name = local.app_name
  description     = "This is static site by amplify"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["amplify.amazonaws.com"]
      type        = "Service"
    }
  }
}
resource "aws_iam_role" "amplify-codecommit" {
  name                = "${local.app_name}_AmplifyCodeCommit"
  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role.*.json)
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSCodeCommitReadOnly"]
}

resource "aws_amplify_app" "static_site_amplify" {
  name                     = local.app_name
  repository               = aws_codecommit_repository.static_site_amplify.clone_url_http
  iam_service_role_arn     = aws_iam_role.amplify-codecommit.arn
  enable_branch_auto_build = true
  build_spec               = file("./build_spec.yml")
  custom_rule {
    source = "/<*>"
    target = "/index.html"
    status = "404"
  }
  environment_variables    = {
    ENV = "dev"
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.static_site_amplify.id
  branch_name = "main"
  stage       = "PRODUCTION"
}

resource "aws_amplify_domain_association" "static_site_amplify" {
  app_id      = aws_amplify_app.static_site_amplify.id
  domain_name = local.domain
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = local.domain_prefix
  }
}