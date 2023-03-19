terraform {
  cloud {
    organization = "Gavin-Sharma"

    workspaces {
      name = "4640"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

variable "base_cidr_block" {
  description = "default cidr block for vpc"
  default     = "10.0.0.0/16"
}

# create vpc
resource "aws_vpc" "main" {
  cidr_block       = var.base_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "acit-4640-vpc"
  }
}

# public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "acit-4640-pub-sub"
  }
}

# private subnet 1
resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "acit-4640-rds-sub1"
  }
}

# private subnet 2
resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-2b"


  tags = {
    Name = "acit-4640-rds-sub2"
  }
}

# create igw
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "acit-4640-igw"
  }
}

# route table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "acit-4640-rt"
  }
}

# associate public ec2 subnet to route table
resource "aws_route_table_association" "public_subnet_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt.id
}

# ec2 security group
resource "aws_security_group" "ec2_sg" {
  name        = "acit-4640-sg-ec2"
  description = "Allow SSH or HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow inbound SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "acit-4640-sg-ec2"
  }
}

# rds security group
resource "aws_security_group" "rds_sg" {
  name        = "acit-4640-sg-rds"
  description = "Allow mysql traffic within the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow mysql inbound"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.base_cidr_block]
  }

  tags = {
    Name = "acit-4640-sg-rds"
  }
}

# get the ami for the most recent version of ubuntu 22.04
# to use include the line below when creating instance
# ami = data.aws_ami.ubuntu.id
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# key pair from local key
resource "aws_key_pair" "local_key" {
  key_name   = "AWS_Key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGad/4rNQGORImcEowoWrKTccE4ouv0hGaoq5uk9uNCZ gavin@LAPTOP-H99IEUPJ"
  #public_key = file("~/.ssh/acit-4640-key.pub")
}

# create ec2 instance
resource "aws_instance" "ec2_instance" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.ec2_sg.id]
  key_name        = aws_key_pair.local_key.key_name
  subnet_id       = aws_subnet.public_subnet.id


  tags = {
    Name = "acit-4640-ec2"
  }
}

# output the public ip address of an ec2 instance
output "instance_public_ip" {
  value = ["${aws_instance.ec2_instance.public_ip}"]
}

# create subnet group
resource "aws_db_subnet_group" "subnet_group" {
  name       = "acit-4640-subnet_group"
  subnet_ids = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]

  tags = {
    Name = "acit-4640-subnet_group"
  }
}

# create rds
resource "aws_db_instance" "rds" {
  allocated_storage      = 10
  identifier             = "acit-4640-rds"
  db_name                = "acit4640rds"
  engine                 = "mysql"
  engine_version         = "8.0.28"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "252002252002"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name

  tags = {
    Name = "acit-4640-rds"
  }
}