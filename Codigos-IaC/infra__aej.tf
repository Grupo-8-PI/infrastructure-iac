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
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "subrede_privada" {
  vpc_id            = aws_vpc.vpc_aej.id
  availability_zone = "us-east-1c"
  cidr_block        = "10.0.0.128/25"
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
# BUCKETS ETL (Staging -> Trusted -> Cured)
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
# LAMBDAS ETL (Staging -> Trusted -> Cured)
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
  availability_zone           = "us-east-1b"
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

# Outputs do S3 e Lambda Excel
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
# OUTPUTS DO SISTEMA ETL
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