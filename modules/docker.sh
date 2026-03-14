#!/usr/bin/env bash
# modules/docker.sh — Docker CE + compose plugin
set -euo pipefail

MAIN_USER="${MAIN_USER:-vini}"

if command -v docker &>/dev/null; then
  # Still ensure user is in docker group (idempotent)
  usermod -aG docker "$MAIN_USER"
  exit 0
fi

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq
apt-get install -y -qq \
  docker-ce docker-ce-cli containerd.io docker-compose-plugin

usermod -aG docker "$MAIN_USER"
systemctl enable docker
systemctl start docker

mark_done "docker"
