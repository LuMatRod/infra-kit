#!/usr/bin/env bash
# core/swap.sh — 2GB swapfile, swappiness=10
set -euo pipefail

if swapon --show | grep -q '/swapfile'; then
  exit 0  # already active, idempotent
fi

if [[ ! -f /swapfile ]]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
fi

swapon /swapfile

grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab

sysctl -w vm.swappiness=10 > /dev/null
grep -q 'vm.swappiness' /etc/sysctl.conf \
  || echo 'vm.swappiness=10' >> /etc/sysctl.conf

mark_done "swap"
