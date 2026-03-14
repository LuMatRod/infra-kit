#!/usr/bin/env bash
# lib/util.sh — utility helpers

# Install gum (charmbracelet) from GitHub releases
install_gum() {
  local os arch pkg_url
  os="linux"
  arch=$(dpkg --print-architecture 2>/dev/null || uname -m)

  # Map arch names
  case "$arch" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    armv7l) arch="armv7" ;;
    *) die "Unsupported architecture: $arch" ;;
  esac

  local version
  version=$(curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest \
    | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')

  pkg_url="https://github.com/charmbracelet/gum/releases/download/v${version}/gum_${version}_${os}_${arch}.tar.gz"

  curl -sL "$pkg_url" | tar -xz -C /usr/local/bin gum
  chmod +x /usr/local/bin/gum
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
