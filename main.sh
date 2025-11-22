#!/bin/bash
set -euo pipefail

# -------------------------
# Color Definitions
# -------------------------
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'
RESET='\e[0m'

# -------------------------
# Animate Logo
# -------------------------
animate_logo() {
  clear
  local logo=(
    "       _ _     _                 "
    "      | (_)   | |                "
    "      | |_ ___| |__  _ __  _   _ "
    "  _   | | / __| '_ \| '_ \| | | |"
    " | |__| | \__ \ | | | | | | |_| |"
    "  \____/|_|___/_| |_|_| |_|__,_|  "
  )
  
  for line in "${logo[@]}"; do
    echo -e "${CYAN}${line}${RESET}"
    sleep 0.2
  done
  echo ""
  sleep 0.5
}

# -------------------------
# Show Animated Logo
# -------------------------
animate_logo

# -------------------------
# ACTUAL URLS (Deobfuscated)
# -------------------------
github_url="https://raw.githubusercontent.com/JoyelTheDev/VM/refs/heads/main/worker.sh"
google_url="https://rough-hall-1486.jishnumondal32.workers.dev"

# -------------------------
# Display Menu
# -------------------------
echo -e "${YELLOW}Select an option:${RESET}"
echo -e "${GREEN}1) GitHub Real VPS${RESET}"
echo -e "${BLUE}2) Google IDX Real VPS${RESET}"
echo -e "${RED}3) Exit${RESET}"
echo -ne "${YELLOW}Enter your choice (1-3): ${RESET}"
read choice

case $choice in
  1)
    echo -e "${GREEN}Running GitHub Real VPS...${RESET}"
    # Downloads and executes: https://vpsmaker.jishnumondal32.workers.dev
    bash <(curl -fsSL "$github_url")
    ;;
  2)
    echo -e "${BLUE}Running Google IDX Real VPS...${RESET}"
    cd
    rm -rf myapp
    rm -rf flutter
    cd vps123
    if [ ! -d ".idx" ]; then
      mkdir .idx
      cd .idx
      cat <<EOF > dev.nix
{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = with pkgs; [
    unzip
    openssh
    git
    qemu_kvm
    sudo
    cdrkit
    cloud-utils
    qemu
  ];

  env = {
    EDITOR = "nano";
  };

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    workspace = {
      onCreate = { };
      onStart = { };
    };

    previews = {
      enable = false;
    };
  };
}
EOF
      cd ..
    fi
    echo -ne "${YELLOW}Do you want to continue? (y/n): ${RESET}"
    read confirm
    case "$confirm" in
      [yY]*)
        # Downloads and executes: https://rough-hall-1486.jishnumondal32.workers.dev
        bash <(curl -fsSL "$google_url")
        ;;
      [nN]*)
        echo -e "${RED}Operation cancelled.${RESET}"
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid input! Operation cancelled.${RESET}"
        exit 1
        ;;
    esac
    ;;
  3)
    echo -e "${RED}Exiting...${RESET}"
    exit 0
    ;;
  *)
    echo -e "${RED}Invalid choice! Please select 1, 2, or 3.${RESET}"
    exit 1
    ;;
esac

echo -e "${CYAN}Made by Jishnu done!${RESET}"
