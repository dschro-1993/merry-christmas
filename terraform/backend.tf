terraform {
  backend "s3" {
    key     = "terraform-state.tf"
    bucket  = "eb08e92d-269e-49a7-b6dc-0b60d8365601"
    region  = "eu-west-1"
  }
}
