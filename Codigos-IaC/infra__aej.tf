terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc_aej" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "vpc_2aej"
  }
}

resource "aws_subnet" "subrede_publica" {
  vpc_id     = aws_vpc.vpc_aej.id
  cidr_block = "10.0.0.0/25"
  tags = {
    Name = "subrede_publica"
  }
}

resource "aws_subnet" "subrede_privada" {
  vpc_id     = aws_vpc.vpc_aej.id
  cidr_block = "10.0.0.128/25"
  tags = {
    Name = "subrede_privada"
  }
}

resource "aws_internet_gateway" "igw_aej" {
  vpc_id = aws_vpc.vpc_aej.id
  tags = {
    Name = "cco-igw"
  }
}

resource "aws_route_table" "route_table_publica" {
  vpc_id = aws_vpc.vpc_aej.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_aej.id
  }

  tags = {
    Name = "subrede-publica-route-table"
  }
}

resource "aws_route_table_association" "subrede_publica" {
  subnet_id      = aws_subnet.subrede_publica.id
  route_table_id = aws_route_table.route_table_publica.id
}

resource "aws_route_table" "rt_aej" {
  vpc_id = aws_vpc.vpc_aej.id
  tags = {
    Name = "rt_aej"
  }
}

resource "aws_security_group" "sg_publica" {
  name        = "sg_publica"
  description = "Permite SSH de qualquer IP"
  vpc_id      = aws_vpc.vpc_aej.id

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
}

resource "aws_security_group" "sg_privada" {
  name        = "sg_privada"
  description = "Permite SSH apenas da VPC"
  vpc_id      = aws_vpc.vpc_aej.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_aej.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_publica" {
  ami                         = "ami-0e86e20dae9224db8"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subrede_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_publica.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.aej_ssh_access.key_name

  tags = {
    Name = "ec2_publica"
  }
}

resource "aws_instance" "ec2_privada" {
  ami                         = "ami-0e86e20dae9224db8"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subrede_privada.id
  vpc_security_group_ids      = [aws_security_group.sg_privada.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.aej_ssh_access.key_name


  tags = {
    Name = "ec2_privada"
  }
}

# Gerar ID aleatório para nomes únicos
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "aej_staging" {
  bucket = "staging-bucket-aej-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "staging"
  }
}

resource "aws_s3_bucket" "aej_trusted" {
  bucket = "trusted-bucket-aej-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "trusted"
  }
}

resource "aws_s3_bucket" "aej_cured" {
  bucket = "cured-bucket-aej-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "cured"
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "aej_ssh_access" {
  key_name   = "aej-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_elb" "elb_aej" {
  name   = "elb-aej"
  subnets = [
    aws_subnet.subrede_publica.id
  ]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  instances = [aws_instance.ec2_publica.id]

  tags = {
    Name = "elb_aej"
  }
}
