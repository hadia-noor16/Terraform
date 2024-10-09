variable "aws_region" {
  description = "Region where my env is deployed"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for my EC2 instance"
  type        = string
  default     = "ami-0fff1b9a61dec8a5f"
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


