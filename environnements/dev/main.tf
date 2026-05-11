terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "agricam_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "agricam-vpc-${var.environnement}"
  }
}

# Subnet
# Subnet
resource "aws_subnet" "agricam_subnet" {
  vpc_id                  = aws_vpc.agricam_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
 

  tags = {
    Name = "agricam-subnet-${var.environnement}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "agricam_igw" {
  vpc_id = aws_vpc.agricam_vpc.id
}
# Route Table
resource "aws_route_table" "agricam_rt" {
  vpc_id = aws_vpc.agricam_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.agricam_igw.id
  }

  tags = {
    Name = "agricam-rt-${var.environnement}"
  }
}

# Association Route Table / Subnet
resource "aws_route_table_association" "agricam_rta" {
  subnet_id      = aws_subnet.agricam_subnet.id
  route_table_id = aws_route_table.agricam_rt.id
}
# Security Group
resource "aws_security_group" "agricam_sg" {
  vpc_id = aws_vpc.agricam_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ip_admin]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "agricam_keypair" {
  key_name   = "agricam-keypair-${var.environnement}"
  public_key = file("~/.ssh/agricam_key.pub")
}
# EC2
resource "aws_instance" "agricam_serveur" {
  ami           = var.ami_id
  instance_type = var.type_instance
  subnet_id     = aws_subnet.agricam_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.agricam_sg.id]

  key_name = aws_key_pair.agricam_keypair.key_name

  tags = {
    Name = "agricam-serveur-${var.environnement}"
  }
}

# S3
resource "aws_s3_bucket" "agricam_stockage" {
  bucket = "agricam-${var.environnement}-bucket-2026"
}
