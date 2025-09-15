# Variables
variable "vpc_id" {
  description = "ID da VPC onde as subnets serão criadas"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block para a subnet pública"
  type        = string
  default     = "10.0.0.0/25"
}

variable "private_subnet_cidr" {
  description = "CIDR block para a subnet privada"
  type        = string
  default     = "10.0.0.128/25"
}

variable "public_subnet_name" {
  description = "Nome da subnet pública"
  type        = string
  default     = "subrede_publica"
}

variable "private_subnet_name" {
  description = "Nome da subnet privada"
  type        = string
  default     = "subrede_privada"
}

# Resources
resource "aws_subnet" "subrede_publica" {
  vpc_id     = var.vpc_id
  cidr_block = var.public_subnet_cidr
  
  tags = {
    Name = var.public_subnet_name
  }
}

resource "aws_subnet" "subrede_privada" {
  vpc_id     = var.vpc_id
  cidr_block = var.private_subnet_cidr
  
  tags = {
    Name = var.private_subnet_name
  }
}

# Outputs
output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = aws_subnet.subrede_publica.id
}

output "private_subnet_id" {
  description = "ID da subnet privada"
  value       = aws_subnet.subrede_privada.id
}
