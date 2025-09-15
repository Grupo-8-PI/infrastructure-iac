resource "tls_private_key" "ec2_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.ec2_ssh_key.public_key_openssh
}

output "private_key_pem" {
  value     = tls_private_key.ec2_ssh_key.private_key_pem
  sensitive = true
}

output "key_name" {
  value = aws_key_pair.ec2_key_pair.key_name
}
# Variables
variable "ami_id" {
  description = "ID da AMI para as instâncias EC2"
  type        = string
  default     = "ami-0e86e20dae9224db8"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "public_subnet_id" {
  description = "ID da subnet pública"
  type        = string
}

variable "private_subnet_id" {
  description = "ID da subnet privada"
  type        = string
}

variable "public_sg_id" {
  description = "ID do security group público"
  type        = string
}

variable "private_sg_id" {
  description = "ID do security group privado"
  type        = string
}

variable "public_instance_name" {
  description = "Nome da instância EC2 pública"
  type        = string
  default     = "ec2_publica"
}

variable "private_instance_name" {
  description = "Nome da instância EC2 privada"
  type        = string
  default     = "ec2_privada"
}

# Resources
resource "aws_instance" "ec2_publica" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.public_sg_id]
  associate_public_ip_address = true

  tags = {
    Name = var.public_instance_name
  }
}

resource "aws_instance" "ec2_privada" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [var.private_sg_id]
  associate_public_ip_address = false

  tags = {
    Name = var.private_instance_name
  }
}

# Outputs
output "public_instance_id" {
  description = "ID da instância EC2 pública"
  value       = aws_instance.ec2_publica.id
}

output "private_instance_id" {
  description = "ID da instância EC2 privada"
  value       = aws_instance.ec2_privada.id
}

output "public_instance_public_ip" {
  description = "IP público da instância EC2 pública"
  value       = aws_instance.ec2_publica.public_ip
}

output "private_instance_private_ip" {
  description = "IP privado da instância EC2 privada"
  value       = aws_instance.ec2_privada.private_ip
}
