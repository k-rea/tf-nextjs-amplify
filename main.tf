locals {
  profile       = "default"
  region        = "ap-northeast-1"
  app_name      = "tf-nextjs-amplify"
  domain        = "testdomain.com"
  domain_prefix = "www"
}

provider "aws" {
  region  = local.region
  profile = local.profile
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
resource "aws_iam_role" "amplify_role" {
  name                = "amplify_deploy_terraform_role"
  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role.*.json)
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSCodeCommitReadOnly"]
}

resource "aws_iam_role_policy" "amplify_role_policy" {
  name = "amplify_iam_role_policy"
  role = aws_iam_role.amplify_role.id

  policy = file("${path.cwd}/iam/amplify_role_policies.json")
}

resource "aws_amplify_app" "static_site_amplify" {
  name                     = local.app_name
  repository               = "https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/test-nextjs-amplify"
  iam_service_role_arn     = aws_iam_role.amplify_role.arn
  build_spec               = file("./build_spec.yml")
  enable_branch_auto_build = true
  enable_auto_branch_creation = true
  enable_branch_auto_deletion = true
  platform = "WEB"
  # Comment this on the first run, trigger a build of your branch, This will added automatically on the console after deployment. Add it here to ensure your subsequent terraform runs don't break your amplify deployment.
#  custom_rule {
#    source = "/<*>"
#    target = "https://xxx.cloudfront.net/<*>"
#    status = "200"
#  }
  custom_rule {
    source = "/<*>"
    target = "/index.html"
    status = "404"
  }
  environment_variables    = {
    ENV = "dev"
    _LIVE_UPDATES = <<ENV
[{"pkg":"next-version","type":"internal","version":"latest"}]
ENV
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.static_site_amplify.id
  branch_name = "main"
  stage       = "PRODUCTION"
  framework = "Next.js - SSR"
  enable_auto_build = true
}

resource "aws_amplify_domain_association" "static_site_amplify" {
  app_id      = aws_amplify_app.static_site_amplify.id
  domain_name = local.domain
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = local.domain_prefix
  }
}
