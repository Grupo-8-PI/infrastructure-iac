# Variables
variable "vpc_id" {
  description = "ID da VPC onde o internet gateway será anexado"
  type        = string
}

variable "igw_name" {
  description = "Nome do Internet Gateway"
  type        = string
  default     = "cco-igw"
}

# Resources
resource "aws_internet_gateway" "igw_aej" {
  vpc_id = var.vpc_id
  
  tags = {
    Name = var.igw_name
  }
}

# Outputs
output "igw_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.igw_aej.id
}
