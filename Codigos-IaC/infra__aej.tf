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
  availability_zone = "us-east-1c"
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

resource "aws_security_group" "sg_publica_http" {
  name = "sg_publica_http"
  description = "Chamadas HTTP na porta 80"
  vpc_id      = aws_vpc.vpc_aej.id

  ingress {
    description = "Chamadas HTTP"
    from_port   = 80
    to_port     = 80
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
resource "aws_instance" "ec2_publica_B" {
  ami                         = "ami-0e86e20dae9224db8"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subrede_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_publica.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.aej_ssh_access.key_name

  tags = {
    Name = "ec2_publica2"
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

# resource "aws_lb" "alb_principal" {
#   name = "alb-principal"
#   internal = false
#   load_balancer_type = "application"
#   security_groups = [aws_security_group.sg_publica_http.id]
#   subnets = [aws_subnet.subrede_publica.id, aws_subnet.subrede_privada.id]
# }

# resource "aws_lb_listener" "http_listener" {
#   load_balancer_arn = aws_lb.alb_principal.arn
#   port = "80"
#   protocol = "HTTP"

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.web_tg.arn
#   }
# }

# resource "aws_lb_target_group_attachment" "ec2_1_attach" {
#   target_group_arn = aws_lb_target_group.web_tg.arn
#   target_id = aws_instance.ec2_publica.id
#   port= 8080  
# }


# resource "aws_lb_target_group_attachment" "ec2_2_attach" {
#   target_group_arn = aws_lb_target_group.web_tg.arn
#   target_id = aws_instance.ec2_publica_B.id
#   port= 8080  
# }

# resource "aws_lb_target_group" "web_tg" {
#   name = "web-instances-target-group"
#   port = 80
#   protocol = "HTTP"
#   vpc_id = aws_vpc.vpc_aej.id
  

#   health_check {
#     path = "/"
#     protocol = "HTTP"
#     matcher = "200"
#   }
# }

data "archive_file" "lambda_zip"{
  type = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

data "aws_iam_role" "lab_role"{
  name="LabRole"
}

resource "aws_lambda_function" "funcao_lambda1" {
  function_name = "funcao1-terraform"
  handler = "lambda_function.lambda_handler"
  runtime = "python3.9"

  role = data.aws_iam_role.lab_role.arn
  filename = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}