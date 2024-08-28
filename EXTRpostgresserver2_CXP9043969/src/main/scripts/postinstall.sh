#!/bin/bash

EXTR_NAME="EXTRpostgresserver2"
PKG_NAME="postgresql13-server"
PREVIOUS_PKG_1="postgresql12-server-12.6-1PGDG.rhel7.x86_64.rpm"
PREVIOUS_PKG_2="postgresql13-server-13.8-1PGDG.rhel7.x86_64.rpm"
# For the Future uplift use the following 2 Previous_PKGs
#PREVIOUS_PKG_1="postgresql13-server-13.8-1PGDG.rhel7.x86_64.rpm"
#PREVIOUS_PKG_2="postgresql13-server-13.8-1PGDG.rhel8.x86_64.rpm"
RPM_PATH="/opt/ericsson/pgsql/rpm2/server/resources/"
RPM_PATH_OLD="/opt/ericsson/pgsql/rpm/server/resources/"


log(){
  msg=$2
  dev_log=/dev/log
  if [[ -S "$dev_log" ]]; then
    case $1 in
    info)
      logger -s -t ${EXTR_NAME}-install -p 'user.notice' "$msg"
    ;;
    error)
      logger -s -t ${EXTR_NAME}-install -p 'user.error' "$msg"
    ;;
    debug)
      logger -s -t ${EXTR_NAME}-install -p 'user.debug' "$msg"
    ;;
    esac
  else
    case $1 in
    info)
      echo "$(date +'%b  %u %T') ${EXTR_NAME}-install [INFO]" "$msg"
    ;;
    error)
      echo "$(date +'%b  %u %T') ${EXTR_NAME}-install [ERROR]" "$msg"
    ;;
    debug)
      echo "$(date +'%b  %u %T') ${EXTR_NAME}-install [DEBUG]" "$msg"
    ;;
    esac
  fi
}


# Setting Package Names
# Determine if RHEL7 or Above
grep "7\." /etc/redhat-release >/dev/null 2>&1
IS_RHEL7=$?
if [ $IS_RHEL7 -eq 0 ]; then
  PKG="postgresql13-server-13.8-1PGDG.rhel7.x86_64.rpm"
  log debug "RHEL7 Deployment: Installing ${PKG}"
else
  PKG="postgresql13-server-13.8-1PGDG.rhel8.x86_64.rpm"
  log debug "RHEL8 Deployment: Installing ${PKG}"
fi


removing_old_rpm() {
  old_rpm=$1
  if [ -f "${old_rpm}" ]; then
    log debug "Removing ${old_rpm}."
    out=$(rm -f ${old_rpm} 2>&1)
    # shellcheck disable=SC2181
    if [ $? -ne 0 ]; then
      log debug "Failed to remove ${old_rpm}. OUTPUT: $out"
    else
      log debug "Successfully removed ${old_rpm}"
    fi
  else
    log debug "${old_rpm} not present"
  fi
}


rpm_install() {
  if [ ! -f "${RPM_PATH}${PKG}" ]; then
    log error "${PKG_NAME} not deployed in desired location"
    exit 1
  else
    log debug "Attempting to install ${PKG_NAME}"
    # Need to remove the RPM lock - inception
    rm -f /var/lib/rpm/.rpm.lock
    out=$(rpm -i "$RPM_PATH${PKG}" --nodeps 2>&1)
    # shellcheck disable=SC2181
    if [ $? -ne 0 ]; then
      /bin/grep 'is already installed' <<< "${out}"
      log debug "${PKG} is already installed"
    else
      installed=$(rpm -qa | grep -c "${PKG_NAME}")
      if [ "${installed}" -eq 0 ]; then
        log error "Issue with installing ${PKG} via rpm -i"
        log error "rpm -i OUTPUT: ${out}"
        exit 1
      fi
    fi
  fi
  log info "Installed ${PKG_NAME} rpm"
}


# Main
log info "Running ${EXTR_NAME} RPM Post-Install"
# For Future remove the following PG13 RPMs
#removing_old_rpm ${RPM_PATH}${PREVIOUS_PKG_1}
#removing_old_rpm ${RPM_PATH}${PREVIOUS_PKG_2}
removing_old_rpm ${RPM_PATH}${PREVIOUS_PKG_1}
# Next line is TD for the old EXTR
removing_old_rpm ${RPM_PATH_OLD}${PREVIOUS_PKG_2}
rpm_install

log info "Finished ${EXTR_NAME} RPM Post-Install"
