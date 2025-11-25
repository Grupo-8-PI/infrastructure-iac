#!/bin/bash
set -euo pipefail

LOG="/var/log/user-data-docker.log"
exec >> "$LOG" 2>&1

echo "=== [$(date)] Início da instalação do Docker e Docker Compose ==="

echo "=== [$(date)] Atualizando pacotes ==="
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "=== [$(date)] Instalando dependências básicas ==="
apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

echo "=== [$(date)] Instalando Docker Engine (repositório oficial) ==="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== [$(date)] Habilitando Docker e adicionando usuário ubuntu ao grupo docker ==="
systemctl enable --now docker
usermod -aG docker ubuntu || true

echo "=== [$(date)] Verificando versão do Docker / Compose ==="
docker --version
docker compose version

echo "=== [$(date)] Testando Docker com container Hello World ==="
docker run --rm hello-world

echo "=== [$(date)] Docker e Docker Compose instalados com sucesso! ==="
echo "=== [$(date)] Para usar Docker sem sudo, faça logout/login ou execute: newgrp docker ==="
echo "=== [$(date)] Fim da instalação ==="
