#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: morganp
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.minecraft.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y jq
msg_ok "Installed Dependencies"

msg_info "Starting Java installation (Temurin 21 via Adoptium)"
JAVA_VERSION="21" setup_java
msg_info "Verifying Java Installation"
if JAVA_BIN=$(command -v java 2>/dev/null); then
  JAVA_REAL=$(readlink -f "$JAVA_BIN")
  JAVA_VER=$(java -version 2>&1 | head -n1)
  msg_ok "Java found at: ${JAVA_BIN} -> ${JAVA_REAL}"
  msg_ok "Version: ${JAVA_VER}"
else
  msg_error "Java binary not found in PATH after setup_java"
  exit 1
fi

msg_info "Setting JAVA_HOME"
echo "JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-amd64" >>/etc/environment
export JAVA_HOME="/usr/lib/jvm/temurin-21-jdk-amd64"
msg_ok "JAVA_HOME set to ${JAVA_HOME}"

msg_info "Downloading Minecraft Server"
mkdir -p /opt/minecraft
MC_MANIFEST=$(curl -fsSL "https://launchermeta.mojang.com/mc/game/version_manifest.json")
MC_VERSION=$(echo "$MC_MANIFEST" | jq -r '.latest.release')
MC_VERSION_URL=$(echo "$MC_MANIFEST" | jq -r --arg v "$MC_VERSION" '.versions[] | select(.id == $v) | .url')
MC_SERVER_URL=$(curl -fsSL "$MC_VERSION_URL" | jq -r '.downloads.server.url')
$STD curl -fsSL "$MC_SERVER_URL" -o /opt/minecraft/server.jar
msg_ok "Downloaded Minecraft Server ${MC_VERSION}"

msg_info "Configuring Minecraft Server"
cat <<EOF >/opt/minecraft/eula.txt
eula=true
EOF
cat <<EOF >/opt/minecraft/server.properties
server-port=25565
motd=A Minecraft Server
difficulty=easy
gamemode=survival
max-players=20
online-mode=true
EOF
msg_ok "Configured Minecraft Server"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft Java Edition Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/minecraft
ExecStart=/usr/bin/java -Xmx1024M -Xms512M -jar /opt/minecraft/server.jar nogui
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now minecraft
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
