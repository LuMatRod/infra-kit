#!/usr/bin/env bash
# core/tailscale.sh — install Tailscale and join tailnet
set -euo pipefail

TAILSCALE_AUTH_KEY="${TAILSCALE_AUTH_KEY:-}"

if [[ -z "$TAILSCALE_AUTH_KEY" ]]; then
  echo "TAILSCALE_AUTH_KEY is not set" >&2
  exit 1
fi

# Install Tailscale
if ! command -v tailscale &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# Join tailnet (idempotent — re-running re-auths cleanly)
tailscale up \
  --authkey="$TAILSCALE_AUTH_KEY" \
  --ssh \
  --accept-routes \
  --hostname="$(hostname)"

systemctl enable tailscaled

mark_done "tailscale"
