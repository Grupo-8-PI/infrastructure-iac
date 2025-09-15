# Variables
variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/24"
}

variable "vpc_name" {
  description = "Nome da VPC"
  type        = string
  default     = "vpc_2aej"
}

# Resources
resource "aws_vpc" "vpc_aej" {
  cidr_block = var.vpc_cidr
  
  tags = {
    Name = var.vpc_name
  }
}

# Outputs
output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.vpc_aej.id
}

output "vpc_cidr_block" {
  description = "CIDR block da VPC"
  value       = aws_vpc.vpc_aej.cidr_block
}
