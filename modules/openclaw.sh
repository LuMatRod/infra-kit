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
Environment=PATH=/usr/local/bin:/usr/bin:/bin
WorkingDirectory=$HOME_DIR
ExecStart=/usr/bin/doppler run --project openclaw --config prd -- /usr/bin/openclaw gateway start
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openclaw

mark_done "openclaw"
