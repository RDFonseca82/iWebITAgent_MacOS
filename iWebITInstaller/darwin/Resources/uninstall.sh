#!/bin/bash

#Generate application uninstallers for macOS.

#Parameters
DATE=`date +%Y-%m-%d`
TIME=`date +%H:%M:%S`
LOG_PREFIX="[$DATE $TIME]"
SERVICE_PLIST="/Library/LaunchDaemons/com.rdfonseca.iWebITService.plist"
AGENT_PLIST="/Library/LaunchAgents/com.rdfonseca.iWebITSysTray.plist"

#Functions
log_info() {
    echo "${LOG_PREFIX}[INFO]" $1
}

log_warn() {
    echo "${LOG_PREFIX}[WARN]" $1
}

log_error() {
    echo "${LOG_PREFIX}[ERROR]" $1
}

#Check running user
if (( $EUID != 0 )); then
    echo "Please run as root."
    exit
fi

log_info "Welcome to Application Uninstaller"
log_info "The following packages will be REMOVED:"
log_info "  __PRODUCT__-__VERSION__"
while true; do
    read -p "Do you wish to continue [Y/n]?" answer
    [[ $answer == "y" || $answer == "Y" || $answer == "" ]] && break
    [[ $answer == "n" || $answer == "N" ]] && exit 0
    echo "Please answer with 'y' or 'n'"
done


#Need to replace these with install preparation script
VERSION=__VERSION__
PRODUCT=__PRODUCT__

echo $HOME

log_info "Application uninstalling process started"

log_info "Stopping any iWebIT instances running"
killall iWebIT

launchctl unload $SERVICE_PLIST
if [ $? -eq 0 ]
then
  log_info "[1/4] Successfully unloaded service"
else
  log_error "[1/4] Could not unload service" >&2
fi

rm $SERVICE_PLIST
if [ $? -eq 0 ]
then
  log_info "[1/4] Successfully deleted service"
else
  log_error "[1/4] Could not delete service" >&2
fi

su - $(basename $HOME) -c 'launchctl unload "${AGENT_PLIST}"'
if [ $? -eq 0 ]
then
  log_info "[2/4] Successfully unloaded agent"
else
  log_error "[2/4] Could not unload agent" >&2
fi

rm $AGENT_PLIST
if [ $? -eq 0 ]
then
  log_info "[2/4] Successfully deleted agent"
else
  log_error "[2/4] Could not delete agent" >&2
fi

#forget from pkgutil
pkgutil --forget "com.rdfonseca.${PRODUCT}" > /dev/null 2>&1
if [ $? -eq 0 ]
then
  log_info "[3/4] Successfully deleted application informations"
else
  log_error "[3/4] Could not delete application informations" >&2
fi

#remove application source distribution
[ -e "__PRODUCT_DIR__" ] && rm -rf "__PRODUCT_DIR__"
if [ $? -eq 0 ]
then
  log_info "[4/4] Successfully deleted application"
else
  log_error "[4/4] Could not delete application" >&2
fi

log_info "Application uninstall process finished"
exit 0
