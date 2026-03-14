#!/usr/bin/env bash
# lib/ui.sh — shared UI helpers

BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

RESULTS=()
FAILED=false

header() {
  clear
  echo ""
  printf "${CYAN}"
  printf "      ▄▄   ▄▄     \n"
  printf "     ▐████████▌    \n"
  printf "    ▐██▀▄▄▄▀██▌    \n"
  printf "   ▗████   ████▖   \n"
  printf "   ▐▘ ▝▀███▀▝ ▝▌   \n"
  printf "       ▌   ▌       \n"
  printf "${RESET}"
  echo ""
  printf "  ${BOLD}infra-kit${RESET}  ${DIM}—  server bootstrap${RESET}\n"
  echo ""
}

step() {
  printf "  ${DIM}▸${RESET} %s\n" "$1"
}

ok() {
  printf "  ${GREEN}✓${RESET} %s\n" "$1"
}

fail() {
  printf "  ${RED}✗${RESET} %s\n" "$1"
}

info() {
  printf "  ${DIM}%s${RESET}\n" "$1"
}

die() {
  echo ""
  printf "  ${RED}${BOLD}Error:${RESET} %s\n" "$1"
  echo ""
  exit 1
}

# Run a module with a gum spinner; capture result
run_module() {
  local label="$1"
  local script="$2"

  if gum spin --title "  $label..." -- bash "$script"; then
    RESULTS+=("$(printf "${GREEN}✓${RESET} %s" "$label")")
  else
    local exit_code=$?
    RESULTS+=("$(printf "${RED}✗${RESET} %s" "$label")")
    FAILED=true
    echo ""
    gum style \
      --border rounded --padding "1 2" --border-foreground 196 \
      "$(gum style --foreground 196 --bold "✗ $label failed (exit $exit_code)")" \
      "" \
      "$(bash "$script" 2>&1 | tail -10 | while IFS= read -r line; do printf "  %s\n" "$line"; done)"
    echo ""
    gum confirm "Continue anyway?" || exit 1
  fi
}

# Mask a secret key for display — show first 10 chars + ...
mask_key() {
  local key="$1"
  if [[ -z "$key" ]]; then
    echo "(not set)"
  else
    echo "${key:0:10}..."
  fi
}
