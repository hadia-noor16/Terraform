/*
Provides utilities for working with Transport Layer Security keys and certificates. 
It provides resources that allow private keys, certificates and certficate requests to be created 
as part of a Terraform deployment.
*/

terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
      version = "4.0.6"
    }

    aws = {
      source = "hashicorp/aws"
      version = "5.70.0"
    }
  }
}
