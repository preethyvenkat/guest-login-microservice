terraform {
  backend "s3" {
    bucket         = "guest-login-tf-state-bucket"
    key            = "guest-login/eks/terraform.tfstate"
    region         = "us-east-1"
  }
}

