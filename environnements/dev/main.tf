terraform {
  required_version = ">= 1.0"

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
#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "agricam_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "agricam-vpc-${var.environnement}"
  }
}

#tfsec:ignore:aws-ec2-no-public-ip-subnet
# Subnet
resource "aws_subnet" "agricam_subnet" {
  vpc_id                  = aws_vpc.agricam_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true #tfsec:ignore:aws-ec2-no-public-ip-subnet

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
  name        = "agricam-sg-${var.environnement}"
  description = "Security group for AgriCam"
  vpc_id      = aws_vpc.agricam_vpc.id

  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "HTTP access"

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH admin access"

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ip_admin]
  }

  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Outbound internet access"

    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "agricam-sg-${var.environnement}"
  }
}

# SSH Key Pair
resource "aws_key_pair" "agricam_keypair" {
  key_name = "agricam-keypair-dev-1"

  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGFB9jJOSBPIlXRNL9pGATkN/HqQFFmucUvaOh/2iWMpEKW6WjepuioV4PFYjhY41O3zFcP320bheYtrFwxfghB62VApHiW0yIzJUK6pobnzoJNkKniqwlxtMKKEB/SPE1wwvdoDIyehSclHBjtIW2AzJk6h9l5grh4Zg5Qzxb2c7izTvFePqCe+evyBGIGhUhp8JaTvqw++0AXJWKhsU21nTkShs1/eD+F5bqIXCR2DDJOZlVuSfBI+XR7iOf+4TuXLFaejbv+wfJ6BL5A14RU4ciPJlFnDOH29L754AbnObnIE5mbQ5JitFYl1ISFXG6tWXH+5f4Dsdc8YeYolWDPdlPfTpxHHi5jtRnMQt0phRW2ypnQGSgoUuDERoMH6gWGzFWbt57k7A4E7Cvm/7WPaK5NlGnGFMMDNuSL+a1KcztE2HiOIyp0mSFtIDZ/+CwdqDIcBYRcJi3YVdxj7fKeZ5bqDiLIWcElNt/Xl0i2j5ps7NKM5aElXD1sBpjcqbdPKSAm+dlLsumpGTRCOUm3E/elUMXn1GCFogrSnPMjiA26VdF1j0A60otXu3iA/6MUKvycKuz/wGpt3UFAT2+qtBa9C6Vmfcl0tjFSbuySazgPW2cutW2v7i658BIqxeNnC6+0ENOkdIndWzzySGKzJvVyEqvbrdLCsYM1oUNCw== cephora@DESKTOP-63DRJ1P"
}
# EC2
resource "aws_instance" "agricam_serveur" {
  ami                         = var.ami_id
  instance_type               = var.type_instance
  subnet_id                   = aws_subnet.agricam_subnet.id
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.agricam_sg.id]

  key_name = aws_key_pair.agricam_keypair.key_name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "agricam-serveur-${var.environnement}"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "agricam_stockage" { #tfsec:ignore:aws-s3-enable-bucket-logging
  bucket = "agricam-dev-bucket-cephora-2026"
}

resource "aws_s3_bucket_versioning" "agricam_versioning" {
  bucket = aws_s3_bucket.agricam_stockage.id

  versioning_configuration {
    status = "Enabled"
  }
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "agricam_encryption" {
  bucket = aws_s3_bucket.agricam_stockage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "agricam_pab" {
  bucket = aws_s3_bucket.agricam_stockage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
