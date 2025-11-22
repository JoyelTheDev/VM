#!/bin/bash

set -euo pipefail

# -------------------------
# Clear screen first
# -------------------------
clear

# -------------------------
# ASCII Logos Animation
# -------------------------

# First logo
cat << "EOF"
       _ _     _                 
      | (_)   | |                
      | |_ ___| |__  _ __  _   _ 
  _   | | / __| '_ \| '_ \| | | |
 | |__| | \__ \ | | | | | | |_| |
  \____/|_|___/_| |_|_| |_|\__,_|  
EOF
sleep 1
clear

# Second logo
cat << "EOF"
888b      88               88           88                       
8888b     88               88           ""    ,d               
88 `8b    88               88                 88                
88  `8b   88   ,adPPYba,   88,dPPYba,   88  MM88MMM  ,adPPYYba,  
88   `8b  88  a8"     "8a  88P'    "8a  88    88     ""     `Y8  
88    `8b 88  8b       d8  88       d8  88    88     ,adPPPPP88  
88     `8888  "8a,   ,a8"  88b,   ,a8"  88    88,    88,    ,88  
88      `888   `"YbbdP"'   8Y"Ybbd8"'   88    "Y888  `"8bbdP"Y8  
EOF
sleep 1
clear

# Third logo
cat << "EOF"
  _    _             _             _                     
 | |  | |           (_)           | |                    
 | |__| | ___  _ __  _ _ __   __ _| |__   ___  _   _ ____ 
 |  __  |/ _ \| '_ \| | '_ \ / _` | '_ \ / _ \| | | |_  / 
 | |  | | (_) | |_) | | | | | (_| | |_) | (_) | |_| |/ /  
 |_|  |_|\___/| .__/|_|_| |_|\__, |_.__/ \___/ \__, /___| 
              | |             __/ |             __/ |     
              |_|            |___/             |___/      
EOF
sleep 1
clear

# -------------------------
# Show Credits
# -------------------------

msg1="Make By Jishnu & Nobita"
msg2="Docker credit by Hopingboyz"

# Green for msg1
echo -e "\033[1;32m$msg1\033[0m"
sleep 0.05

# Blue for msg2
echo -e "\033[1;34m$msg2\033[0m"
sleep 3
clear

# -------------------------
# Run Container
# -------------------------

RAM=15000
CPU=4
DISK_SIZE=100G
CONTAINER_NAME=hopingboyz
IMAGE_NAME=hopingboyz/debain12
VMDATA_DIR="$PWD/vmdata"

mkdir -p "$VMDATA_DIR"

docker run -it --rm \
  --name "$CONTAINER_NAME" \
  --device /dev/kvm \
  -v "$VMDATA_DIR":/vmdata \
  -e RAM="$RAM" \
  -e CPU="$CPU" \
  -e DISK_SIZE="$DISK_SIZE" \
  "$IMAGE_NAME"