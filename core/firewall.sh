#!/usr/bin/env bash
# core/firewall.sh — UFW rules + fail2ban with correct SSH port
set -euo pipefail

SSH_PORT="${SSH_PORT:-2222}"

# UFW — open only what's needed
ufw allow "$SSH_PORT/tcp"
ufw allow 80/tcp
ufw allow 443/tcp
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
