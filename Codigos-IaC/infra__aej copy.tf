##############################################################
# Simplified, low-cost AWS footprint aligned with AEJ diagram #
##############################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
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
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "notification_email" {
  description = "Email que receberá alertas do ambiente"
  type        = string
  default     = "felipeadelungue.gasparotto@gmail.com"
}

variable "ami_id" {
  description = "AMI usada pelas instâncias EC2"
  type        = string
  default     = "ami-0e86e20dae9224db8"
}

variable "backup_notification_email" {
  description = "Email para receber notificações de backup"
  type        = string
  default     = "felipeadelungue.gasparotto@gmail.com"
}

provider "aws" {
  region = var.aws_region
}

locals {
  project_name = "aej-slim"

  common_tags = {
    Project     = local.project_name
    Environment = "lab"
    ManagedBy   = "Terraform"
  }
}

locals {
  docker_install_script = file("${path.module}/docker-and-compose.sh")
  nginx_install_script  = file("${path.module}/scripts/install_nginx.sh")

  private_user_data = <<-EOT
#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
systemctl enable mysql || true
systemctl enable rabbitmq-server || true
systemctl enable redis-server || true
cat <<'DOCKER_SCRIPT' >/usr/local/bin/docker-and-compose.sh
${local.docker_install_script}
DOCKER_SCRIPT
chmod +x /usr/local/bin/docker-and-compose.sh
/usr/local/bin/docker-and-compose.sh
docker --version || true
docker compose version || true
pip3 install --upgrade pip || true
cat <<'MSG' > /etc/motd
${local.project_name}: serviços Java/MySQL, RabbitMQ, Python e hospedados na mesma instância.
MSG
EOT
}

########################################
# Networking
########################################

resource "aws_vpc" "vpc_aej" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-vpc"
  })
}

resource "aws_subnet" "subrede_publica" {
  vpc_id                  = aws_vpc.vpc_aej.id
  cidr_block              = "10.0.0.0/25"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-public-a"
  })
}

resource "aws_subnet" "subrede_privada" {
  vpc_id            = aws_vpc.vpc_aej.id
  cidr_block        = "10.0.0.128/25"
  availability_zone = "${var.aws_region}b"

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-private-b"
  })
}

resource "aws_internet_gateway" "igw_aej" {
  vpc_id = aws_vpc.vpc_aej.id

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-igw"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subrede_publica.id

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-nat-gw"
  })

  depends_on = [aws_internet_gateway.igw_aej]
}

resource "aws_route_table" "route_table_publica" {
  vpc_id = aws_vpc.vpc_aej.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_aej.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-rtb-public"
  })
}

resource "aws_route_table_association" "associacao_subrede_publica" {
  route_table_id = aws_route_table.route_table_publica.id
  subnet_id      = aws_subnet.subrede_publica.id
}

resource "aws_route_table" "rt_aej" {
  vpc_id = aws_vpc.vpc_aej.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-rtb-private"
  })
}

resource "aws_route_table_association" "associacao_subrede_privada" {
  route_table_id = aws_route_table.rt_aej.id
  subnet_id      = aws_subnet.subrede_privada.id
}

########################################
# Security
########################################

resource "aws_security_group" "sg_publica" {
  name        = "${local.project_name}-sg-public"
  description = "Allow SSH/HTTP from the internet"
  vpc_id      = aws_vpc.vpc_aej.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-public"
  })
}

resource "aws_security_group" "sg_privada" {
  name        = "${local.project_name}-sg-private"
  description = "Restrict traffic to inside the VPC"
  vpc_id      = aws_vpc.vpc_aej.id

  ingress {
    description = "Internal SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_aej.cidr_block]
  }

  ingress {
    description = "Service-to-service"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc_aej.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-private"
  })
}

########################################
# SSH key pair
########################################

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "aej_ssh_access" {
  key_name   = "aej-slim-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "ssh_private_key" {
  content              = tls_private_key.ssh_key.private_key_pem
  filename             = "${path.root}/../aej-slim-key.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

########################################
# EC2 instances
########################################

locals {
  common_user_data = <<-EOT
#!/bin/bash
set -euxo pipefail
cat <<'DOCKER_SCRIPT' >/usr/local/bin/docker-and-compose.sh
${local.docker_install_script}
DOCKER_SCRIPT
chmod +x /usr/local/bin/docker-and-compose.sh
/usr/local/bin/docker-and-compose.sh
docker --version || true
docker compose version || true
EOT
}

resource "aws_instance" "ec2_publica_a" {
  ami                         = var.ami_id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.subrede_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_publica.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.aej_ssh_access.key_name
  user_data                   = local.common_user_data

  tags = merge(local.common_tags, {
    Name  = "${local.project_name}-frontend-a"
    Layer = "frontend"
  })
}

resource "aws_instance" "ec2_publica_b" {
  ami                         = var.ami_id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.subrede_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_publica.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.aej_ssh_access.key_name
  user_data                   = local.common_user_data

  tags = merge(local.common_tags, {
    Name  = "${local.project_name}-frontend-b"
    Layer = "frontend"
  })
}

resource "aws_instance" "ec2_privada" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.subrede_privada.id
  vpc_security_group_ids = [aws_security_group.sg_privada.id]
  key_name               = aws_key_pair.aej_ssh_access.key_name
  user_data              = local.private_user_data
  depends_on = [
    aws_nat_gateway.nat,
    aws_route_table_association.associacao_subrede_privada,
  ]

  root_block_device {
    volume_size = 10   
    volume_type = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name  = "${local.project_name}-servicos-privados"
    Layer = "private-services"
    Role  = "java-mysql-rabbitmq-python-redis"
  })
}

resource "aws_instance" "redis" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.subrede_privada.id
  vpc_security_group_ids = [aws_security_group.sg_privada.id]
  key_name               = aws_key_pair.aej_ssh_access.key_name
  user_data              = file("${path.module}/scripts/install_redis.sh")
  depends_on = [
    aws_nat_gateway.nat,
    aws_route_table_association.associacao_subrede_privada,
  ]

  tags = merge(local.common_tags, {
    Name  = "${local.project_name}-redis"
    Layer = "private-services"
    Role  = "redis"
  })
}

########################################
# SNS notifications
########################################

resource "aws_sns_topic" "alerts" {
  name = "${local.project_name}-alerts"

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-alerts"
  })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

########################################
# React static hosting (diagram reference)
########################################

resource "random_id" "react_suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "react_app" {
  bucket        = "${local.project_name}-react-${random_id.react_suffix.hex}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-react"
  })
}

resource "aws_s3_bucket_public_access_block" "react_app" {
  bucket                  = aws_s3_bucket.react_app.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "react_site" {
  bucket = aws_s3_bucket.react_app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPublicRead",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.react_app.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.react_app]
}

########################################
# Buckets legados (site, backup e ETL)
########################################

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "aej_public" {
  bucket = "aej-public-bucket-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "aej-public"
  })
}

resource "aws_s3_bucket_website_configuration" "aej_public" {
  bucket = aws_s3_bucket.aej_public.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "aej_public" {
  bucket = aws_s3_bucket.aej_public.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "aej_public" {
  bucket = aws_s3_bucket.aej_public.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.aej_public.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.aej_public]
}

resource "aws_s3_bucket" "aej_db_backup" {
  bucket = "aej-db-backup-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "aej-db-backup"
  })
}

resource "aws_s3_bucket" "staging" {
  bucket        = "aej-staging-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name        = "aej-staging"
    Environment = "ETL"
  })
}

resource "aws_s3_bucket" "trusted" {
  bucket        = "aej-trusted-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name        = "aej-trusted"
    Environment = "ETL"
  })
}

resource "aws_s3_bucket" "cured" {
  bucket        = "aej-cured-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name        = "aej-cured"
    Environment = "ETL"
  })
}

resource "aws_s3_bucket" "athena_results" {
  bucket        = "athena-results-livros-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name        = "Athena Query Results"
    Environment = "analytics"
  })
}

########################################
# Parameter Store e SNS de backup
########################################

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

resource "aws_sns_topic" "backup_notifications" {
  name         = "aej-db-backup-notifications"
  display_name = "AEJ Database Backup Notifications"

  tags = {
    Name        = "Backup Notifications"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "backup_email" {
  topic_arn = aws_sns_topic.backup_notifications.arn
  protocol  = "email"
  endpoint  = var.backup_notification_email
}

resource "aws_ssm_parameter" "backup_sns_topic" {
  name        = "/aej/backup/sns-topic-arn"
  description = "ARN do SNS Topic para notificações de backup"
  type        = "String"
  value       = aws_sns_topic.backup_notifications.arn

  tags = {
    Name        = "Backup SNS Topic ARN"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

########################################
# Outputs
########################################

output "ssh_private_key_path" {
  description = "Caminho local privado do par de chaves"
  value       = local_file.ssh_private_key.filename
  sensitive   = true
}

output "network" {
  description = "IDs principais da malha de rede"
  value = {
    vpc_id         = aws_vpc.vpc_aej.id
    public_subnet  = aws_subnet.subrede_publica.id
    private_subnet = aws_subnet.subrede_privada.id
  }
}

output "frontend_public_ips" {
  description = "IPs públicos para validação do NGINX básico"
  value = [
    aws_instance.ec2_publica_a.public_ip,
    aws_instance.ec2_publica_b.public_ip
  ]
}

output "backend_private_ips" {
  description = "IPs privados usados para tráfego interno"
  value       = aws_instance.ec2_privada.private_ip
}

output "redis_private_ip" {
  description = "IP privado da instância Redis"
  value       = aws_instance.redis.private_ip
}

output "sns_topic_arn" {
  description = "ARN do tópico SNS para alertas simples"
  value       = aws_sns_topic.alerts.arn
}

output "react_site" {
  description = "Bucket e endpoint usados para hospedar o frontend React"
  value = {
    bucket_name      = aws_s3_bucket.react_app.bucket
    website_endpoint = aws_s3_bucket_website_configuration.react_app.website_endpoint
  }
}

output "s3_public_bucket_name" {
  description = "Bucket legado usado para arquivos públicos"
  value       = aws_s3_bucket.aej_public.bucket
}

output "database_backup_bucket" {
  description = "Bucket destinado aos backups do banco"
  value       = aws_s3_bucket.aej_db_backup.bucket
}

output "etl_buckets" {
  description = "Buckets Staging/Trusted/Cured utilizados no pipeline"
  value = {
    staging = aws_s3_bucket.staging.bucket
    trusted = aws_s3_bucket.trusted.bucket
    cured   = aws_s3_bucket.cured.bucket
  }
}

output "athena_results_bucket" {
  description = "Bucket para armazenar resultados do Athena"
  value       = aws_s3_bucket.athena_results.bucket
}

########################################
# Artefatos das Lambdas (zips e IAM)
########################################

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "archive_file" "excel_processor_zip" {
  type        = "zip"
  source_file = "excel_processor_lambda.py"
  output_path = "excel_processor_lambda.zip"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

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

resource "aws_cloudwatch_log_group" "excel_lambda_logs" {
  name              = "/aws/lambda/excel-processor-terraform"
  retention_in_days = 14
}

resource "aws_lambda_function" "excel_processor" {
  filename         = data.archive_file.excel_processor_zip.output_path
  function_name    = "excel-processor-terraform"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "excel_processor_lambda.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900
  memory_size      = 3008
  source_code_hash = data.archive_file.excel_processor_zip.output_base64sha256

  environment {
    variables = {
      SOURCE_BUCKET = aws_s3_bucket.aej_public.bucket
      OUTPUT_BUCKET = aws_s3_bucket.aej_public.bucket
    }
  }

  depends_on = [aws_cloudwatch_log_group.excel_lambda_logs]
}

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

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.excel_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.aej_public.arn
}

resource "aws_lambda_function" "funcao_lambda1" {
  function_name    = "funcao1-terraform"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = data.aws_iam_role.lab_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_cloudwatch_log_group" "staging_to_trusted_logs" {
  name              = "/aws/lambda/staging-to-trusted-etl"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "trusted_to_cured_logs" {
  name              = "/aws/lambda/trusted-to-cured-etl"
  retention_in_days = 14
}

resource "aws_lambda_function" "staging_to_trusted" {
  filename         = data.archive_file.staging_to_trusted_zip.output_path
  function_name    = "staging-to-trusted-etl"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "staging_to_trusted_lambda.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  memory_size      = 512
  source_code_hash = data.archive_file.staging_to_trusted_zip.output_base64sha256

  environment {
    variables = {
      TRUSTED_BUCKET = aws_s3_bucket.trusted.bucket
    }
  }

  depends_on = [aws_cloudwatch_log_group.staging_to_trusted_logs]
}

resource "aws_lambda_function" "trusted_to_cured" {
  filename         = data.archive_file.trusted_to_cured_zip.output_path
  function_name    = "trusted-to-cured-etl"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "trusted_to_cured_lambda.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  memory_size      = 512
  source_code_hash = data.archive_file.trusted_to_cured_zip.output_base64sha256

  environment {
    variables = {
      CURED_BUCKET = aws_s3_bucket.cured.bucket
    }
  }

  depends_on = [aws_cloudwatch_log_group.trusted_to_cured_logs]
}

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

########################################
# AWS Glue Data Catalog & Athena
########################################

resource "aws_glue_catalog_database" "livros_analytics" {
  name        = "livros_analytics_db"
  description = "Database para análise de vendas de livros - Pipeline ETL"
}

resource "aws_athena_workgroup" "livros_workgroup" {
  name          = "livros_analytics_workgroup"
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

  tags = merge(local.common_tags, {
    Name = "Livros Analytics Workgroup"
  })
}

resource "aws_glue_catalog_table" "cured_livros_table" {
  name          = "vendas_livros"
  database_name = aws_glue_catalog_database.livros_analytics.name
  description   = "Tabela final com apenas vendas de livros (cured bucket)"
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification"         = "csv"
    "delimiter"              = ","
    "skip.header.line.count" = "1"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cured.bucket}/cured/"
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
      name    = "Data"
      type    = "string"
      comment = "Data e hora da compra"
    }

    columns {
      name    = "Dia_da_Semana"
      type    = "string"
      comment = "Dia da semana calculado"
    }

    columns {
      name    = "product_category_name"
      type    = "string"
      comment = "Categoria do produto (livros)"
    }

    columns {
      name    = "seller_city"
      type    = "string"
      comment = "Cidade do vendedor"
    }

    columns {
      name    = "seller_state"
      type    = "string"
      comment = "Estado do vendedor"
    }

    columns {
      name    = "Quantidade"
      type    = "double"
      comment = "Quantidade vendida"
    }

    columns {
      name    = "Obra_Vendida"
      type    = "string"
      comment = "Nome da obra/livro vendido"
    }

    columns {
      name    = "Valor_Pago"
      type    = "string"
      comment = "Valor pago formatado"
    }

    columns {
      name    = "Forma_de_Pagamento"
      type    = "string"
      comment = "Método de pagamento utilizado"
    }
  }
}

########################################
# Outputs - Athena
########################################

output "athena_info" {
  description = "Informações do Athena para análise de dados"
  value = {
    database_name         = aws_glue_catalog_database.livros_analytics.name
    table_name            = aws_glue_catalog_table.cured_livros_table.name
    workgroup_name        = aws_athena_workgroup.livros_workgroup.name
    athena_results_bucket = aws_s3_bucket.athena_results.bucket
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
    login_user   = "admin"
    login_pass   = "aej2025grafana"
    port         = 3000
    
    get_ip_command = "aws ecs list-tasks --cluster grafana-livros-cluster --service-name grafana-livros-service --query 'taskArns[0]' --output text"
    
    instructions = <<-EOT
    
    ========================================
    GRAFANA - INSTRUÇÕES DE ACESSO
    ========================================
    
    1. AGUARDAR DEPLOYMENT (1-3 minutos):
       - ECS está iniciando o container Grafana
       - Verificar status: AWS Console → ECS → Clusters → grafana-livros-cluster
    
    2. OBTER IP PÚBLICO (executar no PowerShell):
       $taskArn = aws ecs list-tasks --cluster grafana-livros-cluster --service-name grafana-livros-service --query 'taskArns[0]' --output text
       $eniId = aws ecs describe-tasks --cluster grafana-livros-cluster --tasks $taskArn --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text
       aws ec2 describe-network-interfaces --network-interface-ids $eniId --query 'NetworkInterfaces[0].Association.PublicIp' --output text
    
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
         * Database: livros_analytics_db
         * Workgroup: livros_analytics_workgroup
         * Output Location: s3://aej-athena-results-<ID>/query-results/
    
    5. CRIAR DASHBOARDS:
       - Explore → Selecionar datasource Athena
       - Executar queries SQL da tabela: vendas_livros
    
    EXEMPLO DE QUERY:
    SELECT seller_state, COUNT(*) as vendas
    FROM vendas_livros
    GROUP BY seller_state
    ORDER BY vendas DESC
    LIMIT 10
    EOT
  }
}