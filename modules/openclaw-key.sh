#!/usr/bin/env bash
# modules/openclaw-key.sh — generate deploy key + wait for GitHub confirmation
# Runs interactively (no spinner) — must be called with run_interactive
set -euo pipefail

MAIN_USER="${MAIN_USER:-vini}"
WORKSPACE_MODE="${WORKSPACE_MODE:-Fresh start}"
WORKSPACE_REPO="${WORKSPACE_REPO:-}"
HOME_DIR="/home/$MAIN_USER"
DEPLOY_KEY_PATH="$HOME_DIR/.ssh/github_deploy"

# Only needed for clone mode
[[ "$WORKSPACE_MODE" != "Clone existing repo" || -z "$WORKSPACE_REPO" ]] && exit 0

# Generate deploy key if not already present
if [[ ! -f "$DEPLOY_KEY_PATH" ]]; then
  sudo -u "$MAIN_USER" ssh-keygen -t ed25519 -C "openclaw@$(hostname)" \
    -f "$DEPLOY_KEY_PATH" -N ""
  sudo -u "$MAIN_USER" bash -c "cat >> ~/.ssh/config << 'EOF'
Host github.com
  IdentityFile ~/.ssh/github_deploy
  StrictHostKeyChecking accept-new
EOF"
fi

DEPLOY_KEY_PUB=$(cat "${DEPLOY_KEY_PATH}.pub")

echo ""
gum style \
  --border rounded --padding "1 2" --border-foreground 214 \
  "$(gum style --foreground 214 --bold '⚠  Add this deploy key to GitHub before continuing')" \
  "" \
  "$DEPLOY_KEY_PUB" \
  "" \
  "$(gum style --foreground 244 'github.com → repo → Settings → Deploy keys → Add deploy key (read-only)')"
echo ""
gum confirm "Done — key added to GitHub?" || exit 1
