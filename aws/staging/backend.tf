resource "aws_s3_bucket" "terraform_remote_backend" {
  bucket = "stg-terraform-remote-backend.piny940.com"
}
terraform {
  backend "s3" {
    bucket = "stg-terraform-remote-backend.piny940.com"
    region = "ap-northeast-1"
    key    = "staging.tfstate"
  }
}
