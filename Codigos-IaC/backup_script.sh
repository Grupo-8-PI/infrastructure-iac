#!/bin/bash
set -euo pipefail

# ========================================
# INSTALAÇÃO DE DEPENDÊNCIAS
# ========================================

echo "=== Verificando e instalando dependências ==="

if command -v apt-get &>/dev/null; then
  echo "Detectado sistema Debian/Ubuntu"
  apt-get update -y && apt-get install -y mysql-client awscli
elif command -v yum &>/dev/null; then
  echo "Detectado sistema RedHat/CentOS"
  yum update -y && yum install -y mysql awscli
fi

echo "✅ Dependências instaladas!"


echo "=== Carregando credenciais seguras do AWS Parameter Store ==="

# Região da AWS
AWS_REGION="us-east-1"

# Busca os parâmetros do Parameter Store
DATABASE=$(aws ssm get-parameter --name "/aej/database/name" --region ${AWS_REGION} --query 'Parameter.Value' --output text)
DB_USER=$(aws ssm get-parameter --name "/aej/database/user" --region ${AWS_REGION} --query 'Parameter.Value' --output text)
DB_PASS=$(aws ssm get-parameter --name "/aej/database/password" --region ${AWS_REGION} --with-decryption --query 'Parameter.Value' --output text)
DB_HOST=$(aws ssm get-parameter --name "/aej/database/host" --region ${AWS_REGION} --query 'Parameter.Value' --output text)
S3_BUCKET=$(aws ssm get-parameter --name "/aej/backup/s3-backup-bucket" --region ${AWS_REGION} --query 'Parameter.Value' --output text)

# Configurações locais
BACKUP_DIR="/tmp/backup"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

echo "✅ Credenciais carregadas com sucesso!"
echo "=== Iniciando backup do banco ${DATABASE} ==="

mkdir -p "${BACKUP_DIR}_${DATE}"

mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DATABASE" > "${BACKUP_DIR}_${DATE}/${DATABASE}_backup_${DATE}.sql"

if [ $? -ne 0 ]; then
  echo "❌ Erro ao realizar o dump do banco de dados"
  exit 1
fi

aws s3 cp "${BACKUP_DIR}_${DATE}/${DATABASE}_backup_${DATE}.sql" "s3://${S3_BUCKET}/mysql-backups/"

if [ $? -eq 0 ]; then
  echo "✅ Backup realizado com sucesso e enviado ao S3"
  rm -rf "${BACKUP_DIR}_${DATE}"
  exit 0
else
  echo "❌ Houve um erro ao enviar o backup para o S3"
  exit 1
fi
