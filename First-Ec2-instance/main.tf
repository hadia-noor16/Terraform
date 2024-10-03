provider "aws" {

  region = "us-east-1"
}

resource "aws_instance" "web" {
   ami = "ami-0ebfd941bbafe70c6"
   instance_type = "t2.micro"

   subnet_id = "subnet-0addb86de1f7595b1"
   vpc_security_group_ids = ["sg-0246c987400301a6b"]

 tags = {
"Terraform" = "true" }
 }
