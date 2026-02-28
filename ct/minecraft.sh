#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="https://raw.githubusercontent.com/morganp/ProxmoxVED/main"
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: morganp
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.minecraft.net/

APP="Minecraft"
var_tags="${var_tags:-gaming;java}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -f /usr/bin/java ]]; then
    msg_error "No Java Installation Found!"
    exit
  fi

  JAVA_VERSION="21" setup_java
  msg_ok "Updated Java successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Connect your Minecraft client to:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:25565${CL}"
