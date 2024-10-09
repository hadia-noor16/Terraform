terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.70.0"
      region = var.aws_region
    }

    tls = {
      source = "hashicorp/tls"
      version = "4.0.7"
    }
  }
}
