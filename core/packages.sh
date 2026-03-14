#!/usr/bin/env bash
# core/packages.sh — base system packages + zsh
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq \
  curl wget git zsh build-essential pkg-config \
  libssl-dev unzip ufw fail2ban ca-certificates gnupg \
  htop jq rsync

# Set timezone to UTC (apps handle local conversion)
timedatectl set-timezone UTC

mark_done "packages"
