# ========================================
# TERRAFORM CONFIGURATION
# ========================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = "us-east-1"
}

# ========================================
# NETWORKING - VPC E SUBNETS
# ========================================

resource "aws_vpc" "vpc_aej" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "vpc_2aej"
  }
}

resource "aws_subnet" "subrede_publica" {
  vpc_id     = aws_vpc.vpc_aej.id
  cidr_block = "10.0.0.0/26"
  tags = {
    Name = "subrede_publica_1a"
  }
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subrede_publica_2" {
  vpc_id     = aws_vpc.vpc_aej.id
  cidr_block = "10.0.0.64/26"
  tags = {
    Name = "subrede_publica_1b"
  }
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "subrede_privada" {
  vpc_id            = aws_vpc.vpc_aej.id
  availability_zone = "us-east-1c"
  cidr_block        = "10.0.0.128/26"
  tags = {
    Name = "subrede_privada_1c"
  }
}

resource "aws_subnet" "subrede_privada_2" {
  vpc_id            = aws_vpc.vpc_aej.id
  availability_zone = "us-east-1d"
  cidr_block        = "10.0.0.192/26"
  tags = {
    Name = "subrede_privada_1d"
  }
}

# ========================================
# NETWORKING - INTERNET GATEWAY E ROTAS
# ========================================

resource "aws_internet_gateway" "igw_aej" {
  vpc_id = aws_vpc.vpc_aej.id
  tags = {
    Name = "cco-igw"
  }
}

# Elastic IP para o NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "nat-gateway-eip-aej"
  }
  depends_on = [aws_internet_gateway.igw_aej]
}

# NAT Gateway na subnet pública (para instâncias privadas acessarem internet)
resource "aws_nat_gateway" "nat_gw_aej" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subrede_publica.id
  
  tags = {
    Name = "nat-gateway-aej"
  }
  
  depends_on = [aws_internet_gateway.igw_aej]
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

resource "aws_route_table_association" "subrede_publica_2" {
  subnet_id      = aws_subnet.subrede_publica_2.id
  route_table_id = aws_route_table.route_table_publica.id
}

resource "aws_route_table" "rt_aej" {
  vpc_id = aws_vpc.vpc_aej.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_aej.id
  }
  
  tags = {
    Name = "rt_aej_privada"
  }
}

resource "aws_route_table_association" "subrede_privada" {
  subnet_id      = aws_subnet.subrede_privada.id
  route_table_id = aws_route_table.rt_aej.id
}

resource "aws_route_table_association" "subrede_privada_2" {
  subnet_id      = aws_subnet.subrede_privada_2.id
  route_table_id = aws_route_table.rt_aej.id
}

# ========================================
# SECURITY GROUPS
# ========================================

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
  name        = "sg_publica_http"
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

# ========================================
# IAM - INSTANCE PROFILE PARA EC2s PRIVADAS
# ========================================

# IAM Role para EC2s privadas (usando LabRole existente como base)
# NOTA: No AWS Academy, tentaremos usar a LabRole existente via Instance Profile

# Instance Profile que permite EC2s usarem a LabRole
resource "aws_iam_instance_profile" "ec2_privada_profile" {
  name = "ec2-privada-backup-profile"
  role = data.aws_iam_role.lab_role.name

}

# ========================================
# EC2 INSTANCES - BLUE ZONE (PÚBLICO)
# ========================================

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

# ========================================
# EC2 INSTANCES - RED ZONE (PRIVADO)
# ========================================

resource "aws_instance" "ec2_privada" {
  ami                         = "ami-0e86e20dae9224db8"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subrede_privada.id
  vpc_security_group_ids      = [aws_security_group.sg_privada.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.aej_ssh_access.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_privada_profile.name
  user_data                   = <<-EOF
  #!/bin/bash
  set -euo pipefail
  
  # Log de execução do user_data
  exec > >(tee /var/log/user-data.log)
  exec 2>&1
  
  echo "=== Iniciando configuração da EC2 Privada ==="
  echo "Data/Hora: $(date)"
  
  # Aguarda inicialização completa do sistema
  sleep 10

  # Cria os scripts
  echo "Criando backup_script.sh..."
  cat <<'SCRIPT_DB' > /home/ubuntu/backup_script.sh
  ${file("backup_script.sh")}
  SCRIPT_DB

  echo "Criando cron_job_config.sh..."
  cat <<'SCRIPT_CRON' > /home/ubuntu/cron_job_config.sh
  ${file("cron_job_config.sh")}
  SCRIPT_CRON

  # Verifica se os scripts foram criados
  if [ ! -f /home/ubuntu/backup_script.sh ]; then
      echo "ERRO: backup_script.sh não foi criado!"
      exit 1
  fi
  
  if [ ! -f /home/ubuntu/cron_job_config.sh ]; then
      echo "ERRO: cron_job_config.sh não foi criado!"
      exit 1
  fi

  # Ajusta permissões e proprietário
  chmod +x /home/ubuntu/backup_script.sh
  chmod +x /home/ubuntu/cron_job_config.sh
  chown ubuntu:ubuntu /home/ubuntu/backup_script.sh
  chown ubuntu:ubuntu /home/ubuntu/cron_job_config.sh

  # Executa configuração do cron
  echo "Configurando cronjob..."
  bash /home/ubuntu/cron_job_config.sh

  echo "=== Configuração concluída com sucesso! ==="
  echo "Logs disponíveis em: /var/log/user-data.log"
  EOF

  tags = {
    Name = "ec2_privada"
  }
}

resource "aws_instance" "ec2_privada_B" {
  ami                         = "ami-0e86e20dae9224db8"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subrede_privada_2.id
  vpc_security_group_ids      = [aws_security_group.sg_privada.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.aej_ssh_access.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_privada_profile.name
  user_data                   = <<-EOF
  #!/bin/bash
  set -euo pipefail
  
  # Log de execução do user_data
  exec > >(tee /var/log/user-data.log)
  exec 2>&1
  
  echo "=== Iniciando configuração da EC2 Privada B ==="
  echo "Data/Hora: $(date)"
  
  # Aguarda inicialização completa do sistema
  sleep 10

  # Cria os scripts
  echo "Criando backup_script.sh..."
  cat <<'SCRIPT_DB' > /home/ubuntu/backup_script.sh
  ${file("backup_script.sh")}
  SCRIPT_DB

  echo "Criando cron_job_config.sh..."
  cat <<'SCRIPT_CRON' > /home/ubuntu/cron_job_config.sh
  ${file("cron_job_config.sh")}
  SCRIPT_CRON

  # Verifica se os scripts foram criados
  if [ ! -f /home/ubuntu/backup_script.sh ]; then
      echo "ERRO: backup_script.sh não foi criado!"
      exit 1
  fi
  
  if [ ! -f /home/ubuntu/cron_job_config.sh ]; then
      echo "ERRO: cron_job_config.sh não foi criado!"
      exit 1
  fi

  # Ajusta permissões e proprietário
  chmod +x /home/ubuntu/backup_script.sh
  chmod +x /home/ubuntu/cron_job_config.sh
  chown ubuntu:ubuntu /home/ubuntu/backup_script.sh
  chown ubuntu:ubuntu /home/ubuntu/cron_job_config.sh

  # Executa configuração do cron
  echo "Configurando cronjob..."
  bash /home/ubuntu/cron_job_config.sh

  echo "=== Configuração concluída com sucesso! ==="
  echo "Logs disponíveis em: /var/log/user-data.log"
  EOF

  tags = {
    Name = "ec2_privada_B"
  }
}

# ========================================
# S3 BUCKETS - ARMAZENAMENTO
# ========================================

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "aej_public" {
  bucket = "aej-public-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "aej-public"
  }
}

resource "aws_s3_bucket_website_configuration" "aej_public_website" {
  bucket = aws_s3_bucket.aej_public.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "aej_public_pab" {
  bucket = aws_s3_bucket.aej_public.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "aej_public_policy" {
  bucket = aws_s3_bucket.aej_public.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.aej_public.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.aej_public_pab]
}

# ========================================
# S3 BUCKETS - BACKUP DATABASE
# ========================================

resource "aws_s3_bucket" "aej_db_backup" {
  bucket = "aej-db-backup-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "aej-db-backup"
  }
}

# ========================================
# AWS SYSTEMS MANAGER - PARAMETER STORE
# ========================================

# Variáveis para credenciais do banco de dados
variable "db_user" {
  description = "Usuário do banco de dados MySQL"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Senha do banco de dados MySQL"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Host/IP do banco de dados MySQL"
  type        = string
  sensitive   = true
}

# Parâmetro: Nome do Banco de Dados
resource "aws_ssm_parameter" "db_name" {
  name        = "/aej/database/name"
  description = "Nome do banco de dados para backup"
  type        = "String"
  value       = "aej_hub"

  tags = {
    Name        = "Database Name"
    ManagedBy   = "Terraform"
  }
}

# Parâmetro: Usuário do Banco de Dados
resource "aws_ssm_parameter" "db_user" {
  name        = "/aej/database/user"
  description = "Usuário do banco de dados"
  type        = "String"
  value       = var.db_user

  tags = {
    Name        = "Database User"
    ManagedBy   = "Terraform"
  }
}

# Parâmetro: Senha do Banco de Dados
resource "aws_ssm_parameter" "db_password" {
  name        = "/aej/database/password"
  description = "Senha do banco de dados (criptografada)"
  type        = "SecureString"
  value       = var.db_password

  tags = {
    Name        = "Database Password"
    ManagedBy   = "Terraform"
    Sensitive   = "true"
  }
}

# Parâmetro: Host do Banco de Dados
resource "aws_ssm_parameter" "db_host" {
  name        = "/aej/database/host"
  description = "Host/endpoint do banco de dados"
  type        = "String"
  value       = var.db_host

  tags = {
    Name        = "Database Host"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Parâmetro: Nome do Bucket S3 para Backup
resource "aws_ssm_parameter" "backup_bucket" {
  name        = "/aej/backup/s3-backup-bucket"
  description = "Nome do bucket S3 para armazenar backups"
  type        = "String"
  value       = aws_s3_bucket.aej_db_backup.bucket

  tags = {
    Name        = "Backup S3 Bucket"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ========================================
# S3 BUCKETS - PIPELINE ETL (Staging -> Trusted -> Cured)
# ========================================

# Bucket Staging - dados brutos
resource "aws_s3_bucket" "staging" {
  bucket        = "aej-staging-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "aej-staging"
    Environment = "ETL"
  }
}

# Bucket Trusted - dados limpos (colunas selecionadas)
resource "aws_s3_bucket" "trusted" {
  bucket        = "aej-trusted-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "aej-trusted"
    Environment = "ETL"
  }
}

# Bucket Cured - dados filtrados (apenas livros)
resource "aws_s3_bucket" "cured" {
  bucket        = "aej-cured-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "aej-cured"
    Environment = "ETL"
  }
}

# ========================================
# SSH KEY PAIR - ACESSO SEGURO ÀS INSTÂNCIAS
# ========================================

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "aej_ssh_access" {
  key_name   = "aej-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Grava a chave privada em um arquivo PEM fora do diretório de execução (na raiz do repo)
resource "local_file" "ssh_private_key" {
  content              = tls_private_key.ssh_key.private_key_pem
  filename             = "${path.root}/../aej-key.pem" # pasta principal do repositório
  file_permission      = "0600"
  directory_permission = "0700"
}

output "ssh_private_key_path" {
  description = "Caminho local (não versionado) da chave privada gerada"
  value       = local_file.ssh_private_key.filename
  sensitive   = true
}

# ========================================
# LOAD BALANCER - APPLICATION LOAD BALANCER
# ========================================

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

# ========================================
# LAMBDA FUNCTIONS - PROCESSAMENTO EXCEL
# ========================================

# Lambda para processamento Excel
data "archive_file" "excel_processor_zip" {
  type        = "zip"
  source_file = "excel_processor_lambda.py"
  output_path = "excel_processor_lambda.zip"
}

# Lambda básico original
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Usando LabRole existente para o Lambda de processamento Excel
# (removido aws_iam_role.excel_lambda_role devido a restrições do AWS Labs)

# CloudWatch Log Group para o Excel Lambda
resource "aws_cloudwatch_log_group" "excel_lambda_logs" {
  name              = "/aws/lambda/excel-processor-terraform"
  retention_in_days = 14
}

# Lambda Function para processamento Excel (PRINCIPAL)
resource "aws_lambda_function" "excel_processor" {
  filename      = data.archive_file.excel_processor_zip.output_path
  function_name = "excel-processor-terraform"
  role          = data.aws_iam_role.lab_role.arn # Usando LabRole existente
  handler       = "excel_processor_lambda.lambda_handler"
  runtime       = "python3.9"
  timeout       = 900  # 15 minutos (máximo)
  memory_size   = 3008 # Máximo RAM disponível

  source_code_hash = data.archive_file.excel_processor_zip.output_base64sha256

  environment {
    variables = {
      SOURCE_BUCKET = aws_s3_bucket.aej_public.bucket
      OUTPUT_BUCKET = aws_s3_bucket.aej_public.bucket
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.excel_lambda_logs
  ]
}

# S3 trigger para o Lambda (quando arquivo .xlsx é enviado)
resource "aws_s3_bucket_notification" "excel_upload_trigger" {
  bucket = aws_s3_bucket.aej_public.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.excel_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "datasets/"
    filter_suffix       = ".xlsx"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

# Permissão para S3 invocar o Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.excel_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.aej_public.arn
}

# Lambda básico original (mantido)
resource "aws_lambda_function" "funcao_lambda1" {
  function_name = "funcao1-terraform"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  role             = data.aws_iam_role.lab_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# ========================================
# LAMBDA FUNCTIONS - PIPELINE ETL (Staging -> Trusted -> Cured)
# ========================================

# Arquivos ZIP para os Lambdas ETL
data "archive_file" "staging_to_trusted_zip" {
  type        = "zip"
  source_file = "staging_to_trusted_lambda.py"
  output_path = "staging_to_trusted_lambda.zip"
}

data "archive_file" "trusted_to_cured_zip" {
  type        = "zip"
  source_file = "trusted_to_cured_lambda.py"
  output_path = "trusted_to_cured_lambda.zip"
}

# CloudWatch Log Groups para os Lambdas ETL
resource "aws_cloudwatch_log_group" "staging_to_trusted_logs" {
  name              = "/aws/lambda/staging-to-trusted-etl"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "trusted_to_cured_logs" {
  name              = "/aws/lambda/trusted-to-cured-etl"
  retention_in_days = 14
}

# Lambda: Staging -> Trusted (filtra colunas)
resource "aws_lambda_function" "staging_to_trusted" {
  filename      = data.archive_file.staging_to_trusted_zip.output_path
  function_name = "staging-to-trusted-etl"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "staging_to_trusted_lambda.lambda_handler"
  runtime       = "python3.9"
  timeout       = 300 # 5 minutos
  memory_size   = 512

  source_code_hash = data.archive_file.staging_to_trusted_zip.output_base64sha256

  environment {
    variables = {
      TRUSTED_BUCKET = aws_s3_bucket.trusted.bucket
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.staging_to_trusted_logs
  ]
}

# Lambda: Trusted -> Cured (filtra apenas livros)
resource "aws_lambda_function" "trusted_to_cured" {
  filename      = data.archive_file.trusted_to_cured_zip.output_path
  function_name = "trusted-to-cured-etl"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "trusted_to_cured_lambda.lambda_handler"
  runtime       = "python3.9"
  timeout       = 300 # 5 minutos
  memory_size   = 512

  source_code_hash = data.archive_file.trusted_to_cured_zip.output_base64sha256

  environment {
    variables = {
      CURED_BUCKET = aws_s3_bucket.cured.bucket
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.trusted_to_cured_logs
  ]
}

# Permissões para S3 invocar os Lambdas ETL
resource "aws_lambda_permission" "staging_invoke_lambda" {
  statement_id  = "AllowS3InvokeFromStaging"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.staging_to_trusted.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.staging.arn
}

resource "aws_lambda_permission" "trusted_invoke_lambda" {
  statement_id  = "AllowS3InvokeFromTrusted"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trusted_to_cured.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.trusted.arn
}

# S3 Notifications (triggers)
resource "aws_s3_bucket_notification" "staging_trigger" {
  bucket = aws_s3_bucket.staging.id

  lambda_function {
    id                  = "csv-trigger"
    lambda_function_arn = aws_lambda_function.staging_to_trusted.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  lambda_function {
    id                  = "xlsx-trigger"
    lambda_function_arn = aws_lambda_function.staging_to_trusted.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".xlsx"
  }

  depends_on = [aws_lambda_permission.staging_invoke_lambda]
}

resource "aws_s3_bucket_notification" "trusted_trigger" {
  bucket = aws_s3_bucket.trusted.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.trusted_to_cured.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.trusted_invoke_lambda]
}

# ========================================
# RABBITMQ - MESSAGE BROKER
# ========================================

resource "aws_security_group" "rabbitmq_sg" {
  name        = "rabbitmq-sg"
  description = "Permite trafego para RabbitMQ e SSH"
  vpc_id      = aws_vpc.vpc_aej.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RabbitMQ AMQP"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RabbitMQ UI"
    from_port   = 15672
    to_port     = 15672
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
    Name = "SG RabbitMQ"
  }
}


resource "aws_instance" "ec2_publica_rabbitmq" {
  ami                         = "ami-0360c520857e3138f"
  instance_type               = "t3.micro"
  # availability_zone removido - será inferido da subnet (us-east-1a)
  key_name                    = aws_key_pair.aej_ssh_access.key_name
  subnet_id                   = aws_subnet.subrede_publica.id
  vpc_security_group_ids      = [aws_security_group.rabbitmq_sg.id]
  associate_public_ip_address = true

  user_data = file("rabbit_mq_ubuntu.sh")

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = tls_private_key.ssh_key.private_key_pem
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "compose.yml"
    destination = "/home/ubuntu/compose.yml"
  }

  depends_on = [aws_key_pair.aej_ssh_access]
}

output "rabbitmq_instance_public_ip" {
  description = "Endereço IP público da instância RabbitMQ"
  value       = aws_instance.ec2_publica_rabbitmq.public_ip
}

output "rabbitmq_ui_url" {
  description = "URL de acesso à interface de gerenciamento do RabbitMQ"
  value       = "http://${aws_instance.ec2_publica_rabbitmq.public_ip}:15672"
}

# ========================================
# OUTPUTS - S3 E LAMBDA EXCEL
# ========================================

output "s3_bucket_name" {
  description = "Nome do bucket S3 público"
  value       = aws_s3_bucket.aej_public.bucket
}

output "s3_website_endpoint" {
  description = "URL público do website S3"
  value       = aws_s3_bucket_website_configuration.aej_public_website.website_endpoint
}

output "excel_lambda_function_name" {
  description = "Nome da função Lambda para processamento Excel"
  value       = aws_lambda_function.excel_processor.function_name
}

output "excel_processing_instructions" {
  description = "Como usar o processador Excel automatizado"
  value       = <<-EOT
    COMO USAR:
    1. Envie arquivos .xlsx para: s3://${aws_s3_bucket.aej_public.bucket}/datasets/
    2. O Lambda processará automaticamente os arquivos
    3. Resultado estará em: s3://${aws_s3_bucket.aej_public.bucket}/outputs/tabelao_tratado.xlsx
    
    COMANDOS AWS CLI:
    aws s3 cp arquivo1.xlsx s3://${aws_s3_bucket.aej_public.bucket}/datasets/
    aws s3 cp arquivo2.xlsx s3://${aws_s3_bucket.aej_public.bucket}/datasets/
    aws s3 cp s3://${aws_s3_bucket.aej_public.bucket}/outputs/tabelao_tratado.xlsx ./
  EOT
}

# ========================================
# OUTPUTS - PIPELINE ETL
# ========================================

output "etl_staging_bucket" {
  description = "Nome do bucket Staging (dados brutos)"
  value       = aws_s3_bucket.staging.bucket
}

output "etl_trusted_bucket" {
  description = "Nome do bucket Trusted (dados limpos)"
  value       = aws_s3_bucket.trusted.bucket
}

output "etl_cured_bucket" {
  description = "Nome do bucket Cured (apenas livros)"
  value       = aws_s3_bucket.cured.bucket
}

output "etl_instructions" {
  description = "Como usar o pipeline ETL automatizado"
  value       = <<-EOT
    ========================================
    PIPELINE ETL AUTOMATIZADO
    ========================================
    
    FLUXO: Staging → Trusted → Cured
    
    PASSO 1 - ENVIAR DADOS BRUTOS:
    aws s3 cp seu_arquivo.csv s3://${aws_s3_bucket.staging.bucket}/
    
    PASSO 2 - AUTOMÁTICO (Staging → Trusted):
    - Lambda filtra colunas: data, dia da semana, feriado, product_category_name,
      seller_city, seller_state, quantidade, obra vendida, valor pago, forma de pagamento
    - Preenche vazios com 'null'
    - Salva em: s3://${aws_s3_bucket.trusted.bucket}/trusted/
    
    PASSO 3 - AUTOMÁTICO (Trusted → Cured):
    - Lambda filtra apenas linhas com 'livro' em product_category_name
    - Mantém preenchimento de 'null' para vazios
    - Salva em: s3://${aws_s3_bucket.cured.bucket}/cured/
    
    BAIXAR DADOS PROCESSADOS:
    aws s3 ls s3://${aws_s3_bucket.cured.bucket}/cured/
    aws s3 cp s3://${aws_s3_bucket.cured.bucket}/cured/ ./dados_cured/ --recursive
    
    MONITORAR LOGS:
    aws logs tail /aws/lambda/staging-to-trusted-etl --follow
    aws logs tail /aws/lambda/trusted-to-cured-etl --follow
  EOT
}

# ====================================
# AWS GLUE DATA CATALOG & ATHENA
# ====================================

# Database do Glue para Athena
resource "aws_glue_catalog_database" "livros_analytics" {
  name = "livros_analytics_db"
  
  description = "Database para análise de vendas de livros - Pipeline ETL"
}

# Bucket para resultados Athena
resource "aws_s3_bucket" "athena_results" {
  bucket        = "athena-results-livros-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "Athena Query Results"
    Environment = "production"
    Purpose     = "Store Athena query results"
  }
}

# Athena Workgroup com configuração de output automática
resource "aws_athena_workgroup" "livros_workgroup" {
  name = "livros_analytics_workgroup"
  
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = {
    Name = "Livros Analytics Workgroup"
  }
}

# Tabela CURED (apenas livros) - Tabela principal para análises
resource "aws_glue_catalog_table" "cured_livros_table" {
  name          = "vendas_livros"
  database_name = aws_glue_catalog_database.livros_analytics.name
  
  description = "Tabela final com apenas vendas de livros (cured bucket)"
  
  table_type = "EXTERNAL_TABLE"
  
  parameters = {
    "classification" = "csv"
    "delimiter"      = ","
    "skip.header.line.count" = "1"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cured.id}/cured/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
      parameters = {
        "separatorChar"          = ","
        "quoteChar"              = "\""
        "escapeChar"             = "\\"
        "skip.header.line.count" = "1"
      }
    }

    columns {
      name = "Data"
      type = "string"
      comment = "Data e hora da compra (order_purchase_timestamp)"
    }

    columns {
      name = "Dia da Semana"
      type = "string"
      comment = "Dia da semana calculado"
    }

    columns {
      name = "product_category_name"
      type = "string"
      comment = "Categoria do produto (livros)"
    }

    columns {
      name = "seller_city"
      type = "string"
      comment = "Cidade do vendedor"
    }

    columns {
      name = "seller_state"
      type = "string"
      comment = "Estado do vendedor"
    }

    columns {
      name = "Quantidade"
      type = "double"
      comment = "Quantidade vendida"
    }

    columns {
      name = "Obra Vendida"
      type = "string"
      comment = "Nome da obra/livro vendido"
    }

    columns {
      name = "Valor Pago"
      type = "string"
      comment = "Valor pago formatado"
    }

    columns {
      name = "Forma de Pagamento"
      type = "string"
      comment = "Método de pagamento utilizado"
    }
  }
}

# ====================================
# OUTPUTS - ATHENA
# ====================================

output "athena_info" {
  description = "Informações do Athena para análise de dados"
  value = {
    database_name = aws_glue_catalog_database.livros_analytics.name
    table_name = aws_glue_catalog_table.cured_livros_table.name
    workgroup_name = aws_athena_workgroup.livros_workgroup.name
    athena_results_bucket = aws_s3_bucket.athena_results.bucket
    
    query_examples = <<-EOT
    
    ========================================
    EXEMPLOS DE QUERIES ATHENA
    ========================================
    
    ACESSO:
    1. Vá para AWS Athena Console
    2. Selecione workgroup: ${aws_athena_workgroup.livros_workgroup.name}
    3. Selecione database: ${aws_glue_catalog_database.livros_analytics.name}
    4. Output location já configurado automaticamente!
    
    QUERIES:
    
    1. Consultar vendas de livros:
       SELECT * FROM ${aws_glue_catalog_table.cured_livros_table.name} LIMIT 10;
    
    2. Total de vendas por estado:
       SELECT seller_state, 
              COUNT(*) as total_vendas, 
              SUM(quantidade) as qtd_total
       FROM ${aws_glue_catalog_table.cured_livros_table.name}
       GROUP BY seller_state
       ORDER BY total_vendas DESC;
    
    3. Vendas por dia da semana:
       SELECT dia_da_semana, COUNT(*) as total
       FROM ${aws_glue_catalog_table.cured_livros_table.name}
       GROUP BY dia_da_semana
       ORDER BY total DESC;
    
    4. Top 10 obras mais vendidas:
       SELECT obra_vendida, SUM(quantidade) as qtd_vendida
       FROM ${aws_glue_catalog_table.cured_livros_table.name}
       GROUP BY obra_vendida
       ORDER BY qtd_vendida DESC
       LIMIT 10;
    
    5. Vendas por cidade (Top 15):
       SELECT seller_city, seller_state, COUNT(*) as total
       FROM ${aws_glue_catalog_table.cured_livros_table.name}
       GROUP BY seller_city, seller_state
       ORDER BY total DESC
       LIMIT 15;
    
    6. Análise por forma de pagamento:
       SELECT forma_de_pagamento, COUNT(*) as total
       FROM ${aws_glue_catalog_table.cured_livros_table.name}
       GROUP BY forma_de_pagamento
       ORDER BY total DESC;
    EOT
  }
}

# ====================================
# GRAFANA NA AWS (ECS FARGATE)
# ====================================

# Security Group para Grafana
resource "aws_security_group" "sg_grafana" {
  name        = "sg_grafana_aej"
  description = "Permite acesso HTTP ao Grafana na porta 3000"
  vpc_id      = aws_vpc.vpc_aej.id

  # Acesso HTTP ao Grafana
  ingress {
    description = "Grafana UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS opcional
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG Grafana AEJ"
  }
}

# ECS Cluster para Grafana
resource "aws_ecs_cluster" "cluster_grafana_aej" {
  name = "grafana-livros-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "Cluster Grafana AEJ"
  }
}

# CloudWatch Log Group para Grafana
resource "aws_cloudwatch_log_group" "grafana_logs" {
  name              = "/ecs/grafana-livros-aej"
  retention_in_days = 7

  tags = {
    Name = "Grafana Logs AEJ"
  }
}

# ECS Task Definition para Grafana
resource "aws_ecs_task_definition" "grafana_task_aej" {
  family                   = "grafana-livros-aej"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "grafana"
      image = "grafana/grafana:latest"
      
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "GF_SECURITY_ADMIN_USER"
          value = "admin"
        },
        {
          name  = "GF_SECURITY_ADMIN_PASSWORD"
          value = "aej2025grafana"
        },
        {
          name  = "GF_INSTALL_PLUGINS"
          value = "grafana-athena-datasource"
        },
        {
          name  = "AWS_DEFAULT_REGION"
          value = "us-east-1"
        },
        {
          name  = "GF_SERVER_ROOT_URL"
          value = "http://localhost:3000"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/grafana-livros-aej"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = {
    Name = "Grafana Task AEJ"
  }

  depends_on = [aws_cloudwatch_log_group.grafana_logs]
}

# ECS Service para Grafana
resource "aws_ecs_service" "grafana_service_aej" {
  name            = "grafana-livros-service"
  cluster         = aws_ecs_cluster.cluster_grafana_aej.id
  task_definition = aws_ecs_task_definition.grafana_task_aej.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.subrede_publica.id]
    security_groups  = [aws_security_group.sg_grafana.id]
    assign_public_ip = true
  }

  tags = {
    Name = "Grafana Service AEJ"
  }
}

# ====================================
# OUTPUTS - GRAFANA
# ====================================

output "grafana_info" {
  description = "Informações de acesso ao Grafana"
  value = {
    cluster_name = aws_ecs_cluster.cluster_grafana_aej.name
    service_name = aws_ecs_service.grafana_service_aej.name
    
    instructions = <<-EOT
    
    ========================================
    GRAFANA - INSTRUÇÕES DE ACESSO
    ========================================
    
    1. AGUARDAR DEPLOYMENT (1-3 minutos):
       - ECS está iniciando o container Grafana
       - Verificar status: AWS Console → ECS → Clusters → grafana-livros-cluster
    
    2. OBTER IP PÚBLICO:
       Execute no terminal:
       aws ecs describe-tasks --cluster grafana-livros-cluster --tasks $(aws ecs list-tasks --cluster grafana-livros-cluster --service-name grafana-livros-service --query 'taskArns[0]' --output text) --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text | ForEach-Object { aws ec2 describe-network-interfaces --network-interface-ids $_ --query 'NetworkInterfaces[0].Association.PublicIp' --output text }
    
    3. ACESSAR GRAFANA:
       URL: http://<IP_PUBLICO>:3000
       Usuário: admin
       Senha: aej2025grafana
    
    4. CONFIGURAR ATHENA DATASOURCE:
       - Settings → Data sources → Add data source
       - Selecionar "Amazon Athena"
       - Configurar:
         * Authentication Provider: AWS SDK Default
         * Default Region: us-east-1
         * Database: ${aws_glue_catalog_database.livros_analytics.name}
         * Workgroup: ${aws_athena_workgroup.livros_workgroup.name}
         * Output Location: s3://${aws_s3_bucket.athena_results.bucket}/query-results/
    
    5. CRIAR DASHBOARDS:
       - Explore → Selecionar datasource Athena
       - Executar queries SQL da tabela: ${aws_glue_catalog_table.cured_livros_table.name}
       - Criar visualizações e painéis
    
    EXEMPLO DE QUERY:
    SELECT seller_state, COUNT(*) as vendas
    FROM ${aws_glue_catalog_table.cured_livros_table.name}
    GROUP BY seller_state
    ORDER BY vendas DESC
    LIMIT 10
    EOT
  }
}

# ========================================
# OUTPUTS - NAT GATEWAY
# ========================================

output "nat_gateway_info" {
  description = "Informações do NAT Gateway"
  value = {
    nat_gateway_id = aws_nat_gateway.nat_gw_aej.id
    elastic_ip     = aws_eip.nat_eip.public_ip
    subnet         = aws_subnet.subrede_publica.id
    
    observacao = <<-EOT
    NAT Gateway configurado com sucesso!
    
    FUNCIONALIDADE:
    - Permite que instâncias privadas acessem a internet (apenas saída)
    - Instâncias privadas NÃO podem receber conexões da internet
    - Tráfego de saída passa pelo NAT Gateway na subnet pública
    - IP público fixo: ${aws_eip.nat_eip.public_ip}
    EOT
  }
}

# ========================================
# OUTPUTS - NETWORKING SUBNETS
# ========================================

output "subnets_info" {
  description = "Informações das subnets criadas"
  value = {
    publicas = {
      subnet_1a = {
        id   = aws_subnet.subrede_publica.id
        cidr = aws_subnet.subrede_publica.cidr_block
        az   = aws_subnet.subrede_publica.availability_zone
      }
      subnet_1b = {
        id   = aws_subnet.subrede_publica_2.id
        cidr = aws_subnet.subrede_publica_2.cidr_block
        az   = aws_subnet.subrede_publica_2.availability_zone
      }
    }
    privadas = {
      subnet_1c = {
        id   = aws_subnet.subrede_privada.id
        cidr = aws_subnet.subrede_privada.cidr_block
        az   = aws_subnet.subrede_privada.availability_zone
      }
      subnet_1d = {
        id   = aws_subnet.subrede_privada_2.id
        cidr = aws_subnet.subrede_privada_2.cidr_block
        az   = aws_subnet.subrede_privada_2.availability_zone
      }
    }
    observacao = "Load Balancers podem agora usar múltiplas AZs nas subnets públicas (us-east-1a e us-east-1b)"
  }
}