#!/usr/bin/env bash
# core/ssh.sh — harden SSH: custom port, no root, key-only
set -euo pipefail

SSH_PORT="${SSH_PORT:-2222}"

mkdir -p /run/sshd

# Apply settings
sed -i '/^Port/d' /etc/ssh/sshd_config
echo "Port $SSH_PORT" >> /etc/ssh/sshd_config

sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Validate config before restarting
sshd -t

# Ubuntu 24 uses socket-activated SSH — disable socket, use service
systemctl disable --now ssh.socket 2>/dev/null || true
systemctl enable ssh
systemctl restart ssh

mark_done "ssh"
