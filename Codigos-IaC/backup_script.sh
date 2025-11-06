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
SNS_TOPIC=$(aws ssm get-parameter --name "/aej/backup/sns-topic-arn" --region ${AWS_REGION} --query 'Parameter.Value' --output text)

# Configurações locais
BACKUP_DIR="/tmp/backup"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

echo "✅ Credenciais carregadas com sucesso!"
echo "=== Iniciando backup do banco ${DATABASE} ==="

mkdir -p "${BACKUP_DIR}_${DATE}"

mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DATABASE" > "${BACKUP_DIR}_${DATE}/${DATABASE}_backup_${DATE}.sql"

if [ $? -ne 0 ]; then
  echo "❌ Erro ao realizar o dump do banco de dados"
  
  # Envia notificação de FALHA
  aws sns publish \
    --topic-arn "${SNS_TOPIC}" \
    --subject "❌ FALHA no Backup do Banco de Dados AEJ" \
    --message "ERRO: Falha ao realizar o dump do banco de dados ${DATABASE}
    
Data/Hora: ${DATE}
Servidor: ${DB_HOST}
Banco: ${DATABASE}
Usuário: ${DB_USER}

Ação necessária: Verificar logs da EC2 e conectividade com o banco de dados.

Log: /var/log/user-data.log" \
    --region ${AWS_REGION}
  
  exit 1
fi

# Calcular tamanho do backup
BACKUP_SIZE=$(du -h "${BACKUP_DIR}_${DATE}/${DATABASE}_backup_${DATE}.sql" | cut -f1)

aws s3 cp "${BACKUP_DIR}_${DATE}/${DATABASE}_backup_${DATE}.sql" "s3://${S3_BUCKET}/mysql-backups/"

if [ $? -eq 0 ]; then
  echo "✅ Backup realizado com sucesso e enviado ao S3"
  
  # Envia notificação de SUCESSO
  aws sns publish \
    --topic-arn "${SNS_TOPIC}" \
    --subject "✅ Backup do Banco de Dados AEJ - Sucesso" \
    --message "Backup realizado com SUCESSO!
    
Data/Hora: ${DATE}
Banco de dados: ${DATABASE}
Servidor: ${DB_HOST}
Tamanho do backup: ${BACKUP_SIZE}
Destino S3: s3://${S3_BUCKET}/mysql-backups/${DATABASE}_backup_${DATE}.sql

Status: ✅ Backup completo e armazenado com segurança no S3.

Próximo backup agendado: Consulte configuração do cron." \
    --region ${AWS_REGION}
  
  rm -rf "${BACKUP_DIR}_${DATE}"
  exit 0
else
  echo "❌ Houve um erro ao enviar o backup para o S3"
  
  # Envia notificação de FALHA no upload S3
  aws sns publish \
    --topic-arn "${SNS_TOPIC}" \
    --subject "❌ FALHA no Upload do Backup para S3" \
    --message "ERRO: Backup criado mas falhou ao enviar para S3

Data/Hora: ${DATE}
Banco de dados: ${DATABASE}
Tamanho do backup: ${BACKUP_SIZE}
Bucket S3: ${S3_BUCKET}

Ação necessária: Verificar permissões IAM da EC2 e acesso ao bucket S3.

Backup local: ${BACKUP_DIR}_${DATE}/${DATABASE}_backup_${DATE}.sql" \
    --region ${AWS_REGION}
  
  exit 1
fi
