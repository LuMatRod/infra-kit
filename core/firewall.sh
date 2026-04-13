#!/usr/bin/env bash
# core/firewall.sh — UFW rules + fail2ban with correct SSH port
set -euo pipefail

SSH_PORT="${SSH_PORT:-2222}"
BOX_TYPE="${BOX_TYPE:-}"

# UFW — SSH always open; 80/443 only for boxes with a public web surface
ufw allow "$SSH_PORT/tcp"

if [[ "$BOX_TYPE" == "App (Docker + Caddy)" || "$BOX_TYPE" == "OpenClaw" ]]; then
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

ufw default deny incoming
ufw default allow outgoing
ufw --force enable

# fail2ban — explicit jail for custom SSH port
cat > /etc/fail2ban/jail.d/sshd.conf << EOF
[sshd]
enabled  = true
port     = $SSH_PORT
logpath  = %(sshd_log)s
backend  = %(sshd_backend)s
maxretry = 5
bantime  = 3600
EOF

systemctl enable fail2ban
systemctl restart fail2ban

mark_done "firewall"
