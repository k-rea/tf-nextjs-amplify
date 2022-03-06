# tf-static-site-amplify

## Install tfenv
```shell
brew install tfenv
tfenv --version
```

## Install terraform
Install terraform by .terraform-version
```shell
tfenv install 
```

Or install terraform for specific version
```shell
tfenv list-remote
tfenv install x.x.x
tfenv use x.x.x
```

## Change local variables
```terraform
locals {
  profile       = "my_profile"
  region        = "ap-northeast-1"
  app_name      = "app_name"
  domain        = "my_domain"
  domain_prefix = "app-name"
}
```

## Check terraform plan
```shell
terraform plan
```

## Aplly plan
```shell
terraform apply
```