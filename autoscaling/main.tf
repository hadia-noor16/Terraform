terraform {
    backend "s3" {
    bucket         = "terraform-asg-hnoor" 
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_launch_template" "tf-lt" {
  name_prefix            = "terraforn-LT"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = ["sg-039b33bfa674b46df"]
  user_data              = filebase64("user_data.sh")
}

resource "aws_autoscaling_group" "TF-ASG" {
  vpc_zone_identifier       = ["subnet-076333c7e353f00d7, subnet-0addb86de1f7595b1"]
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  max_size                  = 5
  min_size                  = 2

  launch_template {
    id      = aws_launch_template.tf-lt.id
    version = "$Latest"
  }
}


