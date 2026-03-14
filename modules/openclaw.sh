#!/usr/bin/env bash
# modules/openclaw.sh — install OpenClaw + systemd unit + workspace
set -euo pipefail

MAIN_USER="${MAIN_USER:-vini}"
WORKSPACE_MODE="${WORKSPACE_MODE:-Fresh start}"
WORKSPACE_REPO="${WORKSPACE_REPO:-}"
DOPPLER_PROJECT="${DOPPLER_PROJECT:-openclaw}"
DOPPLER_CONFIG="${DOPPLER_CONFIG:-prd}"
DOPPLER_SERVICE_TOKEN="${DOPPLER_SERVICE_TOKEN:-}"
HOME_DIR="/home/$MAIN_USER"
WORKSPACE_DIR="$HOME_DIR/.openclaw/workspace"

# Install OpenClaw globally (lands in /usr/bin/openclaw via npm prefix /usr)
npm install -g openclaw

# ─── Workspace ────────────────────────────────────────────────────────────────

mkdir -p "$HOME_DIR/.openclaw"
chown "$MAIN_USER:$MAIN_USER" "$HOME_DIR/.openclaw"

if [[ "$WORKSPACE_MODE" == "Clone existing repo" && -n "$WORKSPACE_REPO" ]]; then
  if [[ ! -d "$WORKSPACE_DIR" ]]; then
    # Deploy key was already generated + confirmed in openclaw-key.sh
    sudo -u "$MAIN_USER" git clone "$WORKSPACE_REPO" "$WORKSPACE_DIR"
  fi
else
  mkdir -p "$WORKSPACE_DIR"
  chown -R "$MAIN_USER:$MAIN_USER" "$HOME_DIR/.openclaw"
fi

# ─── Systemd unit ─────────────────────────────────────────────────────────────

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
Environment=DOPPLER_TOKEN=$DOPPLER_SERVICE_TOKEN
Environment=OPENCLAW_NO_RESPAWN=1
Environment=NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
WorkingDirectory=$HOME_DIR
ExecStart=/usr/bin/doppler run --project $DOPPLER_PROJECT --config $DOPPLER_CONFIG -- /usr/bin/openclaw gateway
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Wire up doppler-resolver from workspace
SCRIPTS_DIR="$HOME_DIR/.openclaw/scripts"
mkdir -p "$SCRIPTS_DIR"
if [[ -f "$WORKSPACE_DIR/scripts/doppler-resolver" ]]; then
  cp "$WORKSPACE_DIR/scripts/doppler-resolver" "$SCRIPTS_DIR/doppler-resolver"
  chmod +x "$SCRIPTS_DIR/doppler-resolver"
  chown "$MAIN_USER:$MAIN_USER" "$SCRIPTS_DIR/doppler-resolver"
fi

systemctl daemon-reload
systemctl enable openclaw

mark_done "openclaw"
