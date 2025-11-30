#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io
systemctl enable docker
systemctl start docker
if ! docker ps --format '{{.Names}}' | grep -q '^redis-server$'; then
  docker run -d --name redis-server \
    --restart unless-stopped \
    -p 6379:6379 \
    redis:7-alpine
fi
