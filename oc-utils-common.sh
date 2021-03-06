# Copyright 2016, 2017 International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

version=1.0
log_file=/var/log/capi-utils.log

# Reset a card
function reset_card() {
  # Set return status
  ret_status=0
  # Timeout for reset
  reset_timeout=30
  reset_count=0
  # get number of cards in system
  n=`ls -d /sys/class/ocxl/IBM* | awk -F"/sys/class/ocxl/" '{ print $2 }' | wc -w`
  # eeh_max_freezes: default number of resets allowed per PCI device per
  # hour. Backup/restore this counter, since if card is rest too often,
  # it would be fenced away.
  if [ -f /sys/kernel/debug/powerpc/eeh_max_freezes ]; then
    eeh_max_freezes=`cat /sys/kernel/debug/powerpc/eeh_max_freezes`
    echo 100000 > /sys/kernel/debug/powerpc/eeh_max_freezes
  fi

  [ -n "$3" ] && printf "$3\n" || printf "Preparing to reset card\n"
  [ -n "$4" ] && reset_timeout=$4
  sleep 5

  printf "Resetting card $1: "
  sleep 3
  c=$1
  printf "reset card is set to \"$c\". Reset!\n"
  printf 0 > /sys/bus/pci/slots/$c/power
  sleep 3
  printf 1 > /sys/bus/pci/slots/$c/power
  sleep 5
  while true; do
    if [[ `ls -d /sys/class/ocxl/IBM* 2> /dev/null | awk -F"/sys/class/ocxl/" '{ print $2 }' | wc -w` == "$n" ]]; then
      break
    fi 
    printf "."
    sleep 1
    reset_count=$((reset_count + 1))
    if [[ $reset_count -eq $reset_timeout ]]; then
      printf "${bold}ERROR:${normal} Reset timeout has occurred\n"
      ret_status=1
      break 
    fi
  done
  printf "\n"

  if [ -f /sys/kernel/debug/powerpc/eeh_max_freezes ]; then
    echo $eeh_max_freezes > /sys/kernel/debug/powerpc/eeh_max_freezes
  fi
  if [ $ret_status -ne 0 ]; then
    exit 1
  else
    printf "Reset complete\n"
  fi
}

# Reset a card and also Reload image
function reload_card() {
  # Set return status
  ret_status=0
  # Timeout for reset
  reset_timeout=30
  reset_count=0
  # get number of cards in system
  n=`ls -d /sys/class/ocxl/IBM* | awk -F"/sys/class/ocxl/" '{ print $2 }' | wc -w`
  # eeh_max_freezes: default number of resets allowed per PCI device per
  # hour. Backup/restore this counter, since if card is rest too often,
  # it would be fenced away.
  if [ -f /sys/kernel/debug/powerpc/eeh_max_freezes ]; then
    eeh_max_freezes=`cat /sys/kernel/debug/powerpc/eeh_max_freezes`
    echo 100000 > /sys/kernel/debug/powerpc/eeh_max_freezes
  fi

  [ -n "$3" ] && printf "$3\n" || printf "Preparing to reset card\n"
  [ -n "$4" ] && reset_timeout=$4
  sleep 5
  modprobe pnv-php
# added by collin for image_reload
  setpci -s ${1:9:4}:00:00.0 638.B=01
  printf "Resetting card $1: Image Reloading ... \n"
  sleep 3
  c=$1
  printf "image reload is set to \"$c\".\nReset Card...\nReload Image...\n"
  printf 0 > /sys/bus/pci/slots/$c/power
  sleep 3
  printf 1 > /sys/bus/pci/slots/$c/power
  sleep 5
  while true; do
    if [[ `ls -d /sys/class/ocxl/IBM* 2> /dev/null | awk -F"/sys/class/ocxl/" '{ print $2 }' | wc -w` == "$n" ]]; then
      break
    fi 
    printf "."
    sleep 1
    reset_count=$((reset_count + 1))
    if [[ $reset_count -eq $reset_timeout ]]; then
      printf "${bold}ERROR:${normal} Reset timeout has occurred\n"
      ret_status=1
      break 
    fi
  done
  printf "\n"

  if [ -f /sys/kernel/debug/powerpc/eeh_max_freezes ]; then
    echo $eeh_max_freezes > /sys/kernel/debug/powerpc/eeh_max_freezes
  fi
  if [ $ret_status -ne 0 ]; then
    exit 1
  else
    printf "Image Reload complete\n"
  fi
}


# stop on non-zero response
set -e

# output formatting
( [[ $- == *i* ]] && bold=$(tput bold) ) || bold=""
( [[ $- == *i* ]] && normal=$(tput sgr0) ) || normal=""

# make sure script runs as root
if [[ $EUID -ne 0 ]]; then
  printf "${bold}ERROR:${normal} This script must run as root (${EUID})\n"
  exit 1
fi

