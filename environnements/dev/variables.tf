variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "af-south-1"
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
  default     = "ami-0c54c7c5f6d73d4f0"
}

variable "ip_admin" {
  description = "Admin IP address"
  type        = string
  default     = "0.0.0.0/0"
}
