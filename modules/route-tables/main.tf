# Variables
variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "igw_id" {
  description = "ID do Internet Gateway"
  type        = string
}

variable "public_subnet_id" {
  description = "ID da subnet pública"
  type        = string
}

variable "public_route_table_name" {
  description = "Nome da tabela de roteamento pública"
  type        = string
  default     = "subrede-publica-route-table"
}

variable "private_route_table_name" {
  description = "Nome da tabela de roteamento privada"
  type        = string
  default     = "rt_aej"
}

# Resources
resource "aws_route_table" "route_table_publica" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name = var.public_route_table_name
  }
}

resource "aws_route_table_association" "subrede_publica" {
  subnet_id      = var.public_subnet_id
  route_table_id = aws_route_table.route_table_publica.id
}

resource "aws_route_table" "rt_aej" {
  vpc_id = var.vpc_id
  
  tags = {
    Name = var.private_route_table_name
  }
}

# Outputs
output "public_route_table_id" {
  description = "ID da tabela de roteamento pública"
  value       = aws_route_table.route_table_publica.id
}

output "private_route_table_id" {
  description = "ID da tabela de roteamento privada"
  value       = aws_route_table.rt_aej.id
}
