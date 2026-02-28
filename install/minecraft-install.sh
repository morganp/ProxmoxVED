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

JAVA_VERSION="21" setup_java

msg_info "Verifying Java Installation"
if JAVA_BIN=$(command -v java 2>/dev/null); then
  JAVA_REAL=$(readlink -f "$JAVA_BIN")
  JAVA_VER=$(java -version 2>&1 | head -n1)
  msg_ok "Java found at: ${JAVA_BIN} -> ${JAVA_REAL}"
  msg_ok "Version: ${JAVA_VER}"
  msg_ok "JAVA_HOME: ${JAVA_HOME:-not set}"
else
  msg_error "Java binary not found in PATH after setup_java"
  exit 1
fi

motd_ssh
customize
cleanup_lxc
