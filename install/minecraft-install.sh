#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Morgan (morganp)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://papermc.io/

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

JAVA_VERSION="21" setup_java

msg_info "Downloading Paper MC"
mkdir -p /opt/minecraft
MC_VERSION=$(curl -fsSL "https://api.papermc.io/v2/projects/paper" | jq -r '.versions[-1]')
MC_BUILD=$(curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/${MC_VERSION}/builds" | jq -r '.builds[-1].build')
curl -fsSL -o /opt/minecraft/server.jar \
  "https://api.papermc.io/v2/projects/paper/versions/${MC_VERSION}/builds/${MC_BUILD}/downloads/paper-${MC_VERSION}-${MC_BUILD}.jar"
echo "${MC_VERSION}" >/opt/minecraft/.mc_version
echo "${MC_BUILD}" >/opt/minecraft/.mc_build
msg_ok "Downloaded Paper MC ${MC_VERSION} (build ${MC_BUILD})"

msg_info "Configuring Minecraft"
cat <<EOF >/opt/minecraft/eula.txt
eula=true
EOF
cat <<EOF >/opt/minecraft/server.properties
server-port=25565
difficulty=easy
gamemode=survival
max-players=20
view-distance=10
simulation-distance=10
online-mode=true
spawn-protection=16
level-name=world
motd=A Minecraft Server
EOF
msg_ok "Configured Minecraft"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/minecraft.service
[Unit]
Description=Paper Minecraft Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/minecraft
ExecStart=/usr/bin/java -Xms1G -Xmx3G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -jar /opt/minecraft/server.jar nogui
Restart=on-failure
RestartSec=5
StandardInput=null

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now minecraft
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
