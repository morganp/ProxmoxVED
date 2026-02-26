#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MorganCSIT
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://brew.sh | Github: https://github.com/Homebrew/brew

function header_info {
  clear
  cat <<"EOF"
    __  __                     __
   / / / /___  ____ ___  ___  / /_  ________ _      __
  / /_/ / __ \/ __ `__ \/ _ \/ __ \/ ___/ _ \ | /| / /
 / __  / /_/ / / / / / /  __/ /_/ / /  /  __/ |/ |/ /
/_/ /_/\____/_/ /_/ /_/\___/_.___/_/   \___/|__/|__/
   (Linuxbrew)

EOF
}
set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
CM="${GN}✓${CL}"
BFR="\\r\\033[K"
HOLD="-"

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_error() {
  local msg="$1"
  echo -e "${BFR} ${RD}✗ ${msg}${CL}"
}

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "homebrew" "addon"

header_info

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Homebrew (Linuxbrew) Installer" --yesno "This Will Install Homebrew (Linuxbrew) on this LXC Container. Proceed?" 10 58

msg_info "Installing Dependencies"
apt-get install -y build-essential git curl file procps &>/dev/null
msg_ok "Installed Dependencies"

msg_info "Detecting Non-Root User"
BREW_USER=$(awk -F: '$3 >= 1000 && $3 < 65534 { print $1; exit }' /etc/passwd)
if [ -z "$BREW_USER" ]; then
  msg_error "No non-root user found (uid >= 1000). Create a user first."
  exit 1
fi
msg_ok "Detected User: $BREW_USER"

msg_info "Setting Up Homebrew Prefix"
export PATH="/usr/sbin:$PATH"
groupadd -f linuxbrew
mkdir -p /home/linuxbrew/.linuxbrew
chown -R "$BREW_USER":linuxbrew /home/linuxbrew
chmod 2775 /home/linuxbrew
chmod 2775 /home/linuxbrew/.linuxbrew
usermod -aG linuxbrew "$BREW_USER"
msg_ok "Set Up Homebrew Prefix"

msg_info "Installing Homebrew"
su - "$BREW_USER" -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' &>/dev/null
msg_ok "Installed Homebrew"

msg_info "Configuring Shell Integration"
cat <<'EOF'> /etc/profile.d/homebrew.sh
#!/bin/bash
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
EOF
chmod +x /etc/profile.d/homebrew.sh

BREW_USER_HOME=$(eval echo "~$BREW_USER")
if ! grep -q 'linuxbrew' "$BREW_USER_HOME/.bashrc" 2>/dev/null; then
  cat >> "$BREW_USER_HOME/.bashrc" << 'EOF'

# Homebrew (Linuxbrew)
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
EOF
fi
msg_ok "Configured Shell Integration"

msg_info "Verifying Installation"
su - "$BREW_USER" -c 'brew --version'
msg_ok "Homebrew Verified"

echo -e "Successfully Installed!! Homebrew is ready for user ${BL}${BREW_USER}${CL}"
