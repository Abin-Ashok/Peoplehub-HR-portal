terraform {
  backend "s3" {
    bucket       = "peoplehub-prod-terraform-state-873593"
    key          = "peoplehub/prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}