provider "aws" {
    region=var.aws_region
}
# Creating securoty group to open SSH port from your IP, port 8080 to open for all traffic and allowing all outbound traffic
resource "aws_security_group" "tf_jenkins_sg" {
  name        = "tf_jenkins_sg"
  description = "Allow https inbound traffic and SSH from my IP"
  vpc_id      = var.vpc_id
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
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.tf_jenkins_sg.id]
  key_name               = aws_key_pair.key_pair.key_name
  user_data              = file("user_data.sh")
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

