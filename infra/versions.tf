terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
  }

  required_version = ">= 0.14.9"
}