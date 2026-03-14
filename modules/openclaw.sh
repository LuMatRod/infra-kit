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
DEPLOY_KEY_PATH="$HOME_DIR/.ssh/github_deploy"

# Install OpenClaw globally (lands in /usr/bin/openclaw via npm prefix /usr)
npm install -g openclaw

# ─── Workspace ────────────────────────────────────────────────────────────────

mkdir -p "$HOME_DIR/.openclaw"
chown "$MAIN_USER:$MAIN_USER" "$HOME_DIR/.openclaw"

if [[ "$WORKSPACE_MODE" == "Clone existing repo" && -n "$WORKSPACE_REPO" ]]; then
  if [[ ! -d "$WORKSPACE_DIR" ]]; then
    # Generate a deploy key for vini to authenticate to GitHub
    if [[ ! -f "$DEPLOY_KEY_PATH" ]]; then
      sudo -u "$MAIN_USER" ssh-keygen -t ed25519 -C "openclaw@$(hostname)" \
        -f "$DEPLOY_KEY_PATH" -N ""
      # Configure SSH to use deploy key for GitHub
      sudo -u "$MAIN_USER" bash -c "cat >> ~/.ssh/config << 'EOF'
Host github.com
  IdentityFile ~/.ssh/github_deploy
  StrictHostKeyChecking accept-new
EOF"
    fi
    # Export public key so summary can display it
    export DEPLOY_KEY_PUB
    DEPLOY_KEY_PUB=$(cat "${DEPLOY_KEY_PATH}.pub")

    # Clone as vini using the deploy key
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

systemctl daemon-reload
systemctl enable openclaw

mark_done "openclaw"
