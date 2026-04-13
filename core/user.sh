#!/usr/bin/env bash
# core/user.sh — create main user, copy SSH keys from GitHub
set -euo pipefail

MAIN_USER="${MAIN_USER:-vini}"
GITHUB_USER="${GITHUB_USER:-}"
EXTRA_SSH_KEYS="${EXTRA_SSH_KEYS:-}"

# Create user if doesn't exist
if ! id "$MAIN_USER" &>/dev/null; then
  adduser --disabled-password --gecos "" "$MAIN_USER"
fi

# Sudo + NOPASSWD
usermod -aG sudo "$MAIN_USER"
echo "$MAIN_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$MAIN_USER"
chmod 440 "/etc/sudoers.d/$MAIN_USER"

# SSH directory
mkdir -p "/home/$MAIN_USER/.ssh"
chmod 700 "/home/$MAIN_USER/.ssh"
touch "/home/$MAIN_USER/.ssh/authorized_keys"
chmod 600 "/home/$MAIN_USER/.ssh/authorized_keys"

# Fetch SSH keys from GitHub
if [[ -n "$GITHUB_USER" ]]; then
  curl -sf "https://github.com/${GITHUB_USER}.keys" \
    >> "/home/$MAIN_USER/.ssh/authorized_keys"
fi

# Append any extra public keys passed directly (e.g. new server-specific keys
# not yet uploaded to GitHub)
if [[ -n "$EXTRA_SSH_KEYS" ]]; then
  echo "$EXTRA_SSH_KEYS" >> "/home/$MAIN_USER/.ssh/authorized_keys"
fi

chown -R "$MAIN_USER:$MAIN_USER" "/home/$MAIN_USER/.ssh"

# Set zsh as default shell
chsh -s "$(which zsh)" "$MAIN_USER"

mark_done "user"
