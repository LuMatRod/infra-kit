#!/usr/bin/env bash
# modules/node.sh — Node.js LTS via NodeSource
set -euo pipefail

if command -v node &>/dev/null; then
  exit 0  # already installed
fi

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y -qq nodejs

# pnpm — faster, disk-efficient npm alternative
npm install -g pnpm

mark_done "node"
