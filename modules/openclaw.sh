#!/usr/bin/env bash
# modules/openclaw.sh — install OpenClaw + systemd unit + workspace
set -euo pipefail

MAIN_USER="${MAIN_USER:-vini}"
WORKSPACE_MODE="${WORKSPACE_MODE:-Fresh start}"
WORKSPACE_REPO="${WORKSPACE_REPO:-}"
HOME_DIR="/home/$MAIN_USER"
WORKSPACE_DIR="$HOME_DIR/.openclaw/workspace"

# Install OpenClaw globally
npm install -g openclaw

# Workspace setup
if [[ "$WORKSPACE_MODE" == "Clone existing repo" && -n "$WORKSPACE_REPO" ]]; then
  if [[ ! -d "$WORKSPACE_DIR" ]]; then
    sudo -u "$MAIN_USER" git clone "$WORKSPACE_REPO" "$WORKSPACE_DIR"
  fi
else
  # Fresh start — let openclaw init create it
  mkdir -p "$WORKSPACE_DIR"
  chown -R "$MAIN_USER:$MAIN_USER" "$HOME_DIR/.openclaw"
fi

# Systemd unit — runs as MAIN_USER, secrets injected via Doppler at runtime
cat > /etc/systemd/system/openclaw.service << EOF
[Unit]
Description=OpenClaw Gateway
After=network.target tailscaled.service
Wants=tailscaled.service

[Service]
Type=simple
User=$MAIN_USER
Environment=HOME=$HOME_DIR
WorkingDirectory=$HOME_DIR
ExecStart=doppler run --project openclaw --config prd -- openclaw gateway start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openclaw

# Set zsh as default shell for MAIN_USER
chsh -s "$(which zsh)" "$MAIN_USER"

mark_done "openclaw"
