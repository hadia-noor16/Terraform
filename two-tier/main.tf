terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.72.1"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

#defining vpc
resource "aws_vpc" "two-tier-vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Two-tier VPC"
  }

}

#Creating public subnet in AZ-A
resource "aws_subnet" "public-1a" {
  vpc_id                  = aws_vpc.two-tier-vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "publicA"
  }
}

#Creating public subnet in AZ-B
resource "aws_subnet" "public-1b" {
  vpc_id                  = aws_vpc.two-tier-vpc.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "publicB"
  }
}


#Creating private subnet in AZ-A
resource "aws_subnet" "private-1a" {
  vpc_id            = aws_vpc.two-tier-vpc.id
  cidr_block        = "10.20.101.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "PrivateA"
  }
}

#Creating private subnet in AZ-B
resource "aws_subnet" "private-1b" {
  vpc_id            = aws_vpc.two-tier-vpc.id
  cidr_block        = "10.20.102.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "PrivateB"
  }
}


#creates internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.two-tier-vpc.id

  tags = {
    Name = "IGW"
  }
}


#creates public RT
resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.two-tier-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RT"
  }
}

# creating public subnet 1 association with public RT
resource "aws_route_table_association" "rt-association-public1" {
  subnet_id      = aws_subnet.public-1a.id
  route_table_id = aws_route_table.publicRT.id
}

# creating public subnet 2 association with public RT
resource "aws_route_table_association" "rt-association-public2" {
  subnet_id      = aws_subnet.public-1b.id
  route_table_id = aws_route_table.publicRT.id
}


# creates Elastic EIP for first NAT Gateway
resource "aws_eip" "eip1" {
  domain = "vpc"
}

# creates Elastic EIP for second NAT Gateway
resource "aws_eip" "eip2" {
  domain = "vpc"
}


# NAT Gateway Public Availability Zone: A
resource "aws_nat_gateway" "natgw-A" {
  subnet_id     = aws_subnet.public-1a.id
  allocation_id = aws_eip.eip1.id
  tags = {
    Name = "NAT-GW-Public-A"
  }
  depends_on = [aws_internet_gateway.igw]
}


#NAT Gateway Public Availability Zone: B
resource "aws_nat_gateway" "natgw-B" {
  subnet_id     = aws_subnet.public-1b.id
  allocation_id = aws_eip.eip2.id
  tags = {
    Name = "NAT-GW-Public-B"
  }
  depends_on = [aws_internet_gateway.igw]
}

#creates private RT for AZ-A
resource "aws_route_table" "privateRT-A" {
  vpc_id = aws_vpc.two-tier-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw-A.id
  }
  tags = {
    Name = "Private-RT-A"
  }
}


#creates private RT for AZ-B
resource "aws_route_table" "privateRT-B" {
  vpc_id = aws_vpc.two-tier-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw-B.id
  }

  tags = {
    Name = "Private-RT-B"
  }
}

# creating private subnet association with Private RT A
resource "aws_route_table_association" "rt-association-privatea" {

  subnet_id      = aws_subnet.private-1a.id
  route_table_id = aws_route_table.privateRT-A.id
}

# creating private subnet association with Private RT B
resource "aws_route_table_association" "rt-association-privateb" {
  subnet_id      = aws_subnet.private-1b.id
  route_table_id = aws_route_table.privateRT-B.id
}

#Creating Security Group for webservers
resource "aws_security_group" "EC2SG" {
  name        = "Two tier-EC2SG"
  description = "Security Group for EC2 webservers for two tier infrastructure"
  vpc_id      = aws_vpc.two-tier-vpc.id
  ingress {
    #cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups =[aws_security_group.alb-sg.id]
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = {
    "Name" = "Instance Security Group"
  }
}

# Creating launch template for Apache webservers
resource "aws_launch_template" "twotier-lt" {
  name_prefix            = "twotier-LT"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = ["${aws_security_group.EC2SG.id}"]
  user_data              = filebase64("user_data.sh")
}

# Auto scaling group for apache webservers
resource "aws_autoscaling_group" "twotier-ASG" {
  vpc_zone_identifier       = [aws_subnet.public-1a.id, aws_subnet.public-1b.id]
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  max_size                  = 5
  min_size                  = 2
  target_group_arns         = ["${aws_lb_target_group.my_tg.arn}"]

  launch_template {
    id      = aws_launch_template.twotier-lt.id
    version = "$Latest"
  }
}

#create a security group for RDS Database Instance
resource "aws_security_group" "rds_sg" {
  name = "rds_sg"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create a RDS Database Instance
resource "aws_db_instance" "two-tier-rds" {
  engine                 = "mysql"
  identifier             = "myrds"
  allocated_storage      = 20
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  username               = var.rdsuser
  password               = var.rdspassword
  parameter_group_name   = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = true
}

# Creating ALB 

#creating target group first
resource "aws_lb_target_group" "my_tg" {
  name        = "target-group-twotier"
  vpc_id      = aws_vpc.two-tier-vpc.id
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    interval            = 30
    path                = "/"
    port                = 80
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200,202"
  }
  #lifecycle { create_before_destroy=true }
}
# In order to register EC2 insatnces to the TG, we need to add TG arn to the autoscaling group
#I did that change in ASG setting above.

#Creating Security Group for Application load balancer
resource "aws_security_group" "alb-sg" {
  name        = "ALB-SG"
  description = "Security Group for ALB"
  vpc_id      = aws_vpc.two-tier-vpc.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = {
    "Name" = "ALB Security Group"
  }
}

# Create an ALB 

resource "aws_lb" "myalb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.public-1a.id, aws_subnet.public-1b.id]

  tags = {
    Name = "My-ALB-twotier"
  }
}

#Create listener rule for ALB
resource "aws_lb_listener" "listenerrule-twotier" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

