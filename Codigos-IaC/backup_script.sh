#!/bin/bash

DATABASE='aej_hub'
BACKUP_DIR='./tmp_bk'
S3_BUCKET='aej-backup'
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

echo "realizando backup do banco ${DATABASE} efs"

mkdir -p "${BACKUP_DIR}_${DATE}"
mysqldump "$DATABASE" > "${BACKUP_DIR}_${DATE}/${DATABASE}_backup_${DATE}.sql"
if [ $? -ne 0 ]; then
  echo "erro ao realizar o dump do banco de dados"
  exit 1
fi

aws s3 cp "${BACKUP_DIR}_${DATE}/${DATABASE}_backup_${DATE}.sql" "s3://${S3_BUCKET}/mysql-backups/"

if [ $? -eq 0 ]; then
  echo "backup realizado com sucesso"
  rm -rf "${BACKUP_DIR}_${DATE}"
  exit 0
else
  echo "houve um erro ao realizar o backup"
  exit 1

fi

