#!/usr/bin/env bash
# infra-kit/setup.sh — VPS bootstrap wizard
# Usage: bash setup.sh
#        bash <(curl -s https://raw.githubusercontent.com/LuMatRod/infra-kit/main/setup.sh)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$SCRIPT_DIR/lib"
CORE="$SCRIPT_DIR/core"
MODULES="$SCRIPT_DIR/modules"

source "$LIB/ui.sh"
source "$LIB/util.sh"

# ─── Preflight ────────────────────────────────────────────────────────────────

preflight() {
  header

  # Must run as root
  if [[ $EUID -ne 0 ]]; then
    die "Run as root: sudo bash setup.sh"
  fi

  step "Checking gum..."
  if ! command -v gum &>/dev/null; then
    info "Installing gum..."
    install_gum
  fi
  ok "gum"

  step "Checking Doppler..."
  if ! command -v doppler &>/dev/null; then
    info "Installing Doppler CLI..."
    curl -Ls https://cli.doppler.com/install.sh | sh &>/dev/null
  fi
  ok "Doppler CLI"

  step "Checking Doppler auth..."
  if ! doppler me &>/dev/null; then
    echo ""
    gum style \
      --border rounded --padding "1 2" --border-foreground 214 \
      "$(gum style --foreground 214 --bold 'Doppler not authenticated.')" \
      "" \
      "Run:  $(gum style --foreground 39 --bold 'doppler login')" \
      "Then: $(gum style --foreground 39 --bold 'bash setup.sh')"
    echo ""
    exit 0
  fi
  ok "Doppler authenticated"

  echo ""
}

# ─── Wizard ───────────────────────────────────────────────────────────────────

wizard() {
  # Box type
  BOX_TYPE=$(gum choose \
    --header "What kind of box is this?" \
    "OpenClaw" \
    "App (Docker + Caddy)" \
    "General purpose")

  echo ""

  # Main username
  MAIN_USER=$(gum input \
    --placeholder "vini" \
    --prompt "  Main username → " \
    --value "vini")

  # SSH port
  SSH_PORT=$(gum input \
    --placeholder "2222" \
    --prompt "  SSH port → " \
    --value "2222")

  # GitHub username (for SSH key fetch)
  GITHUB_USER=$(gum input \
    --placeholder "pipa1806" \
    --prompt "  GitHub username (for SSH keys) → ")

  echo ""

  # Tailscale auth key from Doppler
  step "Fetching Tailscale auth key from Doppler..."
  TAILSCALE_AUTH_KEY=$(doppler secrets get TAILSCALE_AUTH_KEY \
    --project infra-kit --config prd --plain 2>/dev/null || true)
  if [[ -z "$TAILSCALE_AUTH_KEY" ]]; then
    TAILSCALE_AUTH_KEY=$(gum input \
      --password \
      --prompt "  Tailscale auth key (not found in Doppler) → ")
  else
    ok "Tailscale auth key"
  fi

  echo ""

  # Module selection based on box type
  case "$BOX_TYPE" in
    "OpenClaw")
      DEFAULT_MODULES="Node.js + npm,OpenClaw,Doppler CLI"
      ;;
    "App (Docker + Caddy)")
      DEFAULT_MODULES="Docker,Caddy,Doppler CLI"
      ;;
    "General purpose")
      DEFAULT_MODULES=""
      ;;
  esac

  SELECTED_MODULES=$(gum choose \
    --no-limit \
    --header "Modules to install (space to toggle):" \
    --selected "$DEFAULT_MODULES" \
    "Node.js + npm" \
    "OpenClaw" \
    "Docker" \
    "Caddy" \
    "Doppler CLI")

  echo ""

  # OpenClaw workspace (only if OpenClaw selected)
  WORKSPACE_MODE=""
  WORKSPACE_REPO=""
  if echo "$SELECTED_MODULES" | grep -q "OpenClaw"; then
    WORKSPACE_MODE=$(gum choose \
      --header "OpenClaw workspace:" \
      "Clone existing repo" \
      "Fresh start")

    if [[ "$WORKSPACE_MODE" == "Clone existing repo" ]]; then
      WORKSPACE_REPO=$(gum input \
        --placeholder "git@github.com:LuMatRod/workspace" \
        --prompt "  Workspace repo URL → ")
    fi
    echo ""
  fi

  # Confirm
  gum style \
    --border rounded --padding "1 2" \
    "$(gum style --bold 'Ready to run:')" \
    "" \
    "  Box type:    $BOX_TYPE" \
    "  User:        $MAIN_USER" \
    "  SSH port:    $SSH_PORT" \
    "  GitHub user: $GITHUB_USER" \
    "  Tailscale:   $(mask_key "$TAILSCALE_AUTH_KEY")" \
    "  Modules:     $(echo "$SELECTED_MODULES" | tr '\n' ' ')" \
    "$(if [[ -n "$WORKSPACE_REPO" ]]; then echo "  Workspace:   $WORKSPACE_REPO"; fi)"

  echo ""

  gum confirm "Run setup?" || die "Aborted."
}

# ─── Run ──────────────────────────────────────────────────────────────────────

run_setup() {
  export MAIN_USER SSH_PORT GITHUB_USER TAILSCALE_AUTH_KEY LIB

  # Core (always)
  run_module "User + SSH hardening"     "$CORE/user.sh"
  run_module "SSH hardening"            "$CORE/ssh.sh"
  run_module "UFW firewall"             "$CORE/firewall.sh"
  run_module "Packages"                 "$CORE/packages.sh"
  run_module "Swap (2GB)"               "$CORE/swap.sh"
  run_module "Unattended upgrades"      "$CORE/upgrades.sh"
  run_module "Tailscale"                "$CORE/tailscale.sh"

  # Modules
  if echo "$SELECTED_MODULES" | grep -q "Node.js"; then
    run_module "Node.js + npm" "$MODULES/node.sh"
  fi
  if echo "$SELECTED_MODULES" | grep -q "OpenClaw"; then
    WORKSPACE_MODE="$WORKSPACE_MODE" WORKSPACE_REPO="$WORKSPACE_REPO" \
      run_module "OpenClaw" "$MODULES/openclaw.sh"
  fi
  if echo "$SELECTED_MODULES" | grep -q "Docker"; then
    run_module "Docker" "$MODULES/docker.sh"
  fi
  if echo "$SELECTED_MODULES" | grep -q "Caddy"; then
    run_module "Caddy" "$MODULES/caddy.sh"
  fi
  if echo "$SELECTED_MODULES" | grep -q "Doppler CLI"; then
    run_module "Doppler CLI" "$MODULES/doppler.sh"
  fi

  # Verify
  run_module "Verification" "$SCRIPT_DIR/verify.sh"
}

# ─── Summary ──────────────────────────────────────────────────────────────────

summary() {
  echo ""
  gum style --border rounded --padding "1 2" --bold "Setup complete"
  echo ""

  for result in "${RESULTS[@]}"; do
    echo "  $result"
  done

  echo ""

  if [[ "$WORKSPACE_MODE" == "Fresh start" ]] || [[ -z "$WORKSPACE_MODE" ]]; then
    gum style --foreground 244 "  Next: configure OpenClaw via \`openclaw config\`"
  fi

  gum style --foreground 244 "  SSH: ssh -p $SSH_PORT $MAIN_USER@<ip>"
  gum style --foreground 244 "  Or via Tailscale: ssh $MAIN_USER@<tailscale-hostname>"
  echo ""
}

# ─── Main ─────────────────────────────────────────────────────────────────────

preflight
wizard
run_setup
summary
