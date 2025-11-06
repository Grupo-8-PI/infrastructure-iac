#!/bin/bash
# cron_job.sh

# Garante que o cron esteja instalado
if ! command -v crontab &> /dev/null; then
  yum install -y cronie
  systemctl enable crond
  systemctl start crond
fi

(crontab -l 2>/dev/null; echo "0 17 * * * /home/ec2-user/scripts/backup_script.sh >> /var/log/backup_script.log 2>&1") | crontab -
echo "Tarefa de backup agendada no cron."