#!/usr/bin/env bash
# verify.sh — post-setup sanity checks
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

SSH_PORT="${SSH_PORT:-2222}"
MAIN_USER="${MAIN_USER:-vini}"

CHECKS_PASSED=0
CHECKS_FAILED=0

check() {
  local label="$1"
  local cmd="$2"

  if eval "$cmd" &>/dev/null; then
    ok "$label"
    ((CHECKS_PASSED++))
  else
    fail "$label"
    ((CHECKS_FAILED++))
  fi
}

echo ""
gum style --bold "  Verification"
echo ""

check "User '$MAIN_USER' exists"          "id $MAIN_USER"
check "SSH on port $SSH_PORT"             "ss -tlnp | grep -q ':$SSH_PORT'"
check "UFW active"                        "ufw status | grep -q 'Status: active'"
check "fail2ban running"                  "systemctl is-active --quiet fail2ban"
check "Swap active"                       "swapon --show | grep -q /swapfile"
check "Tailscale connected"               "tailscale status | grep -q 'logged in'"
check "Unattended upgrades enabled"       "systemctl is-enabled --quiet unattended-upgrades"

# Optional checks
if command -v node &>/dev/null; then
  check "Node.js installed"              "node --version"
fi
if command -v openclaw &>/dev/null; then
  check "OpenClaw installed"             "openclaw --version"
  check "OpenClaw service enabled"       "systemctl is-enabled --quiet openclaw"
fi
if command -v docker &>/dev/null; then
  check "Docker running"                 "systemctl is-active --quiet docker"
fi

echo ""
if [[ $CHECKS_FAILED -eq 0 ]]; then
  gum style --foreground 46 --bold "  All checks passed ($CHECKS_PASSED/$((CHECKS_PASSED + CHECKS_FAILED)))"
else
  gum style --foreground 214 --bold "  $CHECKS_FAILED check(s) failed — review above"
fi
echo ""
