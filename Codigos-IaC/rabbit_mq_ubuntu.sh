#!/bin/bash
set -euo pipefail

LOG="/var/log/user-data-rabbitmq.log"
exec >> "$LOG" 2>&1

echo "=== [$(date)] Início da configuração da instância RabbitMQ ==="

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
docker --version || true
docker compose version || true

COMPOSE_FILE="/home/ubuntu/compose.yml"

echo "=== [$(date)] Aguardando arquivo de compose provido pelo Terraform: $COMPOSE_FILE ==="
for i in $(seq 1 30); do
  if [ -f "$COMPOSE_FILE" ]; then
    echo "=== [$(date)] Arquivo encontrado (tentativa $i). Subindo stack... ==="
    # Ajusta permissões (provisioner pode ter enviado como root)
    chown ubuntu:ubuntu "$COMPOSE_FILE"
    chmod 644 "$COMPOSE_FILE"
    docker compose -f "$COMPOSE_FILE" pull || true
    docker compose -f "$COMPOSE_FILE" up -d
    STACK_UP=1
    break
  fi
  echo "Arquivo ainda não disponível. Tentativa $i/30. Aguardando 10s..."
  sleep 10
done

if [ -z "${STACK_UP:-}" ]; then
  echo "=== [$(date)] ERRO: compose.yml não chegou a tempo. Verifique o provisioner Terraform. ==="
  exit 1
fi

echo "=== [$(date)] Containers em execução ==="
docker ps

echo "=== [$(date)] RabbitMQ disponível (porta 15672 para UI) ==="
echo "Credenciais padrão: admin / admin (alterar em produção)."
echo "=== [$(date)] Fim da configuração ==="
