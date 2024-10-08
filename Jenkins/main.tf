provider "aws" {
region = "us-east-1"
}
# Creating securoty group to open SSH port from your IP, port 8080 to open for all traffic and allowing all outbound traffic
resource "aws_security_group" "tf_jenkins_sg" {
  name        = "tf_jenkins_sg"
  description = "Allow https inbound traffic and SSH from my IP"
  vpc_id      = "vpc-0af945834a669fd8d"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["67.190.91.100/32"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tf_jenkins_sg"
  }
}

# Creating an EC2 instance with Amazon Linux AMI ID, SG, key pair to associate and user data to install in EC2
resource "aws_instance" "jenkins-ec2" {
  ami           = "ami-0fff1b9a61dec8a5f"
  instance_type = "t3.micro"
  vpc_security_group_ids =[aws_security_group.tf_jenkins_sg.id]
  key_name  = aws_key_pair.key_pair.key_name
  user_data = file("user_data.sh")
  tags = {
    Name = "jenkins-ec2"
  }
}

# Creating an S3 bucket for Jenkins artifacts
resource "aws_s3_bucket" "jenkins-artifact" {
  bucket = "jenkins-artifact-hnoor"

  tags = {
    Name = "Jenkins-artifact"
  }
}

