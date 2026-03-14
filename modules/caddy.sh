#!/usr/bin/env bash
# modules/caddy.sh — Caddy reverse proxy
set -euo pipefail

if command -v caddy &>/dev/null; then
  exit 0
fi

apt-get install -y -qq debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  | tee /etc/apt/sources.list.d/caddy-stable.list

apt-get update -qq
apt-get install -y -qq caddy

systemctl enable caddy

mark_done "caddy"
