#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Morgan (morganp)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://papermc.io/

APP="Minecraft"
var_tags="${var_tags:-game;java}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/minecraft/server.jar ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  MC_VERSION=$(cat /opt/minecraft/.mc_version)
  CURRENT_BUILD=$(cat /opt/minecraft/.mc_build)
  LATEST_BUILD=$(curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/${MC_VERSION}/builds" | jq -r '.builds[-1].build')

  if [[ "${CURRENT_BUILD}" == "${LATEST_BUILD}" ]]; then
    msg_ok "No update required. Already on Paper build ${CURRENT_BUILD} for Minecraft ${MC_VERSION}."
    exit
  fi

  msg_info "Stopping ${APP}"
  systemctl stop minecraft
  msg_ok "Stopped ${APP}"

  msg_info "Updating Paper MC to build ${LATEST_BUILD}"
  curl -fsSL -o /opt/minecraft/server.jar \
    "https://api.papermc.io/v2/projects/paper/versions/${MC_VERSION}/builds/${LATEST_BUILD}/downloads/paper-${MC_VERSION}-${LATEST_BUILD}.jar"
  echo "${LATEST_BUILD}" >/opt/minecraft/.mc_build
  msg_ok "Updated Paper MC to build ${LATEST_BUILD}"

  msg_info "Starting ${APP}"
  systemctl start minecraft
  msg_ok "Started ${APP}"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Connect with the Minecraft client at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:25565${CL}"
