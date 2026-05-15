variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east"
}

variable "environnement" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "type_instance" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Ubuntu AMI ID"
  type        = string
}

variable "ip_admin" {
  description = "Admin IP address"
  type        = string
}
