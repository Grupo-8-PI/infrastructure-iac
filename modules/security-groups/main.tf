# Variables
variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block da VPC"
  type        = string
}

variable "public_sg_name" {
  description = "Nome do security group público"
  type        = string
  default     = "sg_publica"
}

variable "public_sg_description" {
  description = "Descrição do security group público"
  type        = string
  default     = "Permite SSH de qualquer IP"
}

variable "private_sg_name" {
  description = "Nome do security group privado"
  type        = string
  default     = "sg_privada"
}

variable "private_sg_description" {
  description = "Descrição do security group privado"
  type        = string
  default     = "Permite SSH apenas da VPC"
}

# Resources
resource "aws_security_group" "sg_publica" {
  name        = var.public_sg_name
  description = var.public_sg_description
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = var.public_sg_name
  }
}

resource "aws_security_group" "sg_privada" {
  name        = var.private_sg_name
  description = var.private_sg_description
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.private_sg_name
  }
}

# Outputs
output "public_sg_id" {
  description = "ID do security group público"
  value       = aws_security_group.sg_publica.id
}

output "private_sg_id" {
  description = "ID do security group privado"
  value       = aws_security_group.sg_privada.id
}
