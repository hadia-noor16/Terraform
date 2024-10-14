variable "aws_region" {
  description = "Region where my env is deployed"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for my EC2 instance"
  type        = string
  default     = "ami-00f251754ac5da7f0"
}

variable "instance_type" {
  description = "instance size"
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "VPC ID for my infrastructure"
  type        = string
  default     = "vpc-0af945834a669fd8d"
}


