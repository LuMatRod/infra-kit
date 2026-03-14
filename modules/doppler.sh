#!/usr/bin/env bash
# modules/doppler.sh — Doppler CLI (standalone install, no auth)
set -euo pipefail

if command -v doppler &>/dev/null; then
  exit 0
fi

curl -Ls https://cli.doppler.com/install.sh | sh

mark_done "doppler"
