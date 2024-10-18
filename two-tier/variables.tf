variable "aws_region" {
  description = "Region where my env is deployed"
  type        = string
  default     = "us-east-1"
}

variable "access_key" {
  description = "Admin Access key to AWS console"
}
variable "secret_key" {
  description = "Secret key to AWS console"
}

variable "rdsuser" {
  description = "Username for RDS database"
}

variable "rdspassword" {
  description = "Password for RDS database"
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