#!/usr/bin/env bash
# lib/util.sh — utility helpers

# Install gum (charmbracelet) via official apt repo
install_gum() {
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
    | tee /etc/apt/sources.list.d/charm.list > /dev/null
  apt-get update -qq
  apt-get install -y -qq gum
}

# Check if a module has already run (idempotency marker)
module_done() {
  local marker="/var/lib/infra-kit/$1.done"
  [[ -f "$marker" ]]
}

mark_done() {
  local marker="/var/lib/infra-kit/$1.done"
  mkdir -p /var/lib/infra-kit
  touch "$marker"
}
