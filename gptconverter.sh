#!/bin/bash
# MBR to GPT converter based on mbr2gpt, written and copyright by RonR (https://forums.raspberrypi.com/viewtopic.php?t=196778)
# Adapted and improved for RPi5 by MCPat 2024 (https://nvme.mcpat.com/)
#
# To run the converter use the following commands:
# Option 1:
# cd
# wget https://nvme.mcpat.com/gptconverter.sh
# chmod +x gptconverter.sh
# sudo ./gptconverter.sh
#
# Option 2:
# sudo -i
# bash <(curl -s https://nvme.mcpat.com/gptconverter.sh)
#
# Changelog
# v0.9
#  - First release
# v1.0
#  - Check firstboot
#  - config.txt entries
#
# Initialize variables
DEVICE=/dev/nvme0n1
MNTPATH="/tmp/gptconverter-mnt"
MNTED=FALSE
FIRSTBOOT=FALSE

# Fix language settings for utf8
export LC_ALL=C

# Terminal colors
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

# Whether apt update has ran
AptUpdated="0"

# Prints a line with color using terminal codes
Print_Style() {
  printf "%s\n" "${2}$1${NORMAL}"
}

# Install apt package
Install_Apt_Package() {
  echo "Install $1"
  if [ "$AptUpdated" -ne "1" ]; then
    export AptUpdated="1"
    apt-get update
  fi
  apt-get install --no-install-recommends "$1" -y
}

# Compare Version
function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

errexit()
{
  echo ""
  Print_Style "$1" "$RED"
  echo ""
  if [ "${MNTED}" = "TRUE" ]; then
    umount "${MNTPATH}/" &> /dev/null
  fi
  rm -rf "${MNTPATH}/" &> /dev/null
  exit 1
}

mntpart()
{
  if [ ! -d "${MNTPATH}/" ]; then
    mkdir "${MNTPATH}/"
    if [ $? -ne 0 ]; then
      errexit "Unable to make partition mount point"
    fi
  fi
  mount "$1" "${MNTPATH}/"
  if [ $? -ne 0 ]; then
    errexit "Unable to mount $2 partition"
  fi
  MNTED=TRUE
}

umntpart()
{
  umount "${MNTPATH}/"
  if [ $? -ne 0 ]; then
    errexit "Unable to unmount partition"
  fi
  MNTED=FALSE
  rm -r "${MNTPATH}/"
}

# Check if script is running as root first
if [[ "$(whoami)" != "root" ]]; then
  errexit "$0 must be run as root user! Example: sudo ./gptconverter.sh"
fi

Print_Style "Pre checks ..." "$YELLOW"
# Get host information
if [[ "$(cat /proc/device-tree/model | grep -c "Pi 5")" > 0 ]]; then
  Print_Style "It's a Pi5 ..." "$NORMAL"
else
  errexit "It's not a Pi5 ..."
fi

if [ ! $(version $(cat /etc/debian_version)) -ge $(version "12.4") ]; then
	errexit "Debian version is not up to date ..."
else
	Print_Style "Debian version is $(cat /etc/debian_version) ..." "$NORMAL"
fi

# NVMe exists ?
if [ ! -b "$DEVICE" ]; then
  errexit "NVMe does not exist!"
fi
Print_Style "NVMe found ..." "$NORMAL"

#Partitions
DEVICE_P="${DEVICE}"
DEVICE_P+='p'
DriveSuffix=$(echo "$DEVICE" | cut -d"/" -f3)
if [ -z "$DriveSuffix" ]; then
  DriveSuffix=$(echo "$BootDrive" | cut -d"/" -f2)
fi
if [ -z "$DriveSuffix" ]; then
  DriveSuffix=$(echo "$BootDrive" | cut -d"/" -f1)
fi
if [ -z "$DriveSuffix" ]; then
  DriveSuffix="$DEVICE"
fi
Drivesuffix_P="${DriveSuffix}"
Drivesuffix_P+='p'
totalPartitions=$(grep -c "$Drivesuffix_P[0-9]" /proc/partitions)
echo "Total partitions: $totalPartitions"
for i in $(seq 1 1 $totalPartitions)
do
	if grep "$Drivesuffix_P"$i /etc/mtab > /dev/null 2>&1; then
		errexit "$Drivesuffix_P$i is mounted!"
	fi
done
Print_Style "NVMe has no mounted partitions ..." "$NORMAL"

# First boot check
#Print_Style "Check firstboot ..." "$NORMAL"
mntpart "${DEVICE_P}1" "BOOT"
if [[ "$(cat "${MNTPATH}/cmdline.txt" | grep -c "firstboot")" > 0 ]]; then
    umntpart
    errexit "System needs firstly a boot from NVMe, remove SD and reboot, then poweroff, insert SD again and run this script again ..."
    #FIRSTBOOT=TRUE
    #Print_Style "First boot detected ..." "$NORMAL"
else
    Print_Style "First boot already done ..." "$NORMAL"
fi
umntpart

# Install required components
Print_Style "Fetching required components ..." "$YELLOW"
if [ -z "$(which gparted)" ]; then Install_Apt_Package "gparted"; fi
Print_Style "gparted installed ..." "$NORMAL"
if [ -z "$(which gdisk)" ]; then Install_Apt_Package "gdisk"; fi
Print_Style "gdisk installed ..." "$NORMAL"

# Get drive informations
Print_Style "Fetching informations ..." "$YELLOW"
PTTYPE="$(blkid ${DEVICE} | sed -n 's|^.*PTTYPE="\(\S\+\)".*|\1|p')"
PTTYPE="$(tr [a-z] [A-Z] <<< "${PTTYPE}")"
if [ "${PTTYPE}" = "DOS" ]; then
  PTTYPE="MBR"
fi
if [[ "${PTTYPE}" != "MBR" && "${PTTYPE}" != "GPT" ]]; then
  errexit "Unsupported partition table type!"
fi
echo "Partition table type is ${PTTYPE}"
if [ "${PTTYPE}" = "MBR" ]; then
  echo -n "Ok to convert ${DEVICE} to GPT (y/n)? "
  while read -r -n 1 -s answer; do
    if [[ "${answer}" = [yYnN] ]]; then
      echo "${answer}"
      if [[ "${answer}" = [yY] ]]; then
        break
      else
        errexit "Aborted"
      fi
    fi
  done
  sgdisk -z "${DEVICE}" &> /dev/null
fi

# Check if partition overlaps and if unallocated space exists
INFO="$(gdisk -l ${DEVICE} 2> /dev/null)"
START=$(sed -n "s|^\s\+$totalPartitions\s\+\(\S\+\).*|\1|p" <<< "${INFO}")
SHRINK=FALSE
EXPAND=FALSE
if [ $(grep -c "Warning! Secondary partition table overlaps the last partition" <<< "${INFO}") -ne 0 ]; then
  echo "ROOT partition overlaps the Secondary partition table area"
  echo -n "Ok to resize ROOT partition (y/n)? "
  while read -r -n 1 -s answer; do
    if [[ "${answer}" = [yYnN] ]]; then
      echo "${answer}"
      if [[ "${answer}" = [yY] ]]; then
        break
      else
        errexit "Aborted"
      fi
    fi
  done
  SHRINK=TRUE
elif [[ "$(parted /dev/nvme0n1 unit GB print free | grep 'Free Space' | tail -n1 | awk '{print $3}')" != "0.00GB" ]]; then
  echo -n "Expand last partition to use all available space (y/n)? "
  while read -r -n 1 -s answer; do
    if [[ "${answer}" = [yYnN] ]]; then
      echo "${answer}"
      if [[ "${answer}" = [yY] ]]; then
        EXPAND=TRUE
      fi
      break
    fi
  done
fi

# Run process
if [[ "${PTTYPE}" = "MBR" || "${SHRINK}" = "TRUE" || "${EXPAND}" = "TRUE" ]]; then
  Print_Style "Start converting ..." "$YELLOW"
  if [ "${SHRINK}" = "TRUE" ]; then
    resize2fs -f -M "${DEVICE_P}${totalPartitions}" > /dev/null 2>&1
	Print_Style "Shrinked partition ..." "$NORMAL"
  fi
  if [[ "${SHRINK}" = "TRUE" || "${EXPAND}" = "TRUE" ]]; then
    gdisk "${DEVICE}" <<EOF &> /dev/null
d
${totalPartitions}
n
${totalPartitions}
${START}


w
y
EOF
    resize2fs -f "${DEVICE_P}${totalPartitions}" > /dev/null 2>&1
    Print_Style "Resized partition ..." "$NORMAL"
  fi
  gdisk "${DEVICE}" <<EOF &> /dev/null
r
h
1
n
0c
n
n
w
y
EOF
  Print_Style "Expanded ..." "$NORMAL"
  Print_Style "Start writing cmdline.txt, config.txt and fstab ..." "$YELLOW"
  PARTUUID_1="$(blkid ${DEVICE_P}1 | sed -n 's|^.*PARTUUID="\(\S\+\)".*|\1|p')"
  PARTUUID_2="$(blkid ${DEVICE_P}2 | sed -n 's|^.*PARTUUID="\(\S\+\)".*|\1|p')"
  mntpart "${DEVICE_P}1" "BOOT"
  sed -i '/^[[:space:]]*#/!s| init=/usr/lib/raspi-config/init_resize\.sh||' "${MNTPATH}/cmdline.txt"
  sed -i "/^[[:space:]]*#/!s|^\(.*root=\)\S\+\(\s\+.*\)$|\1PARTUUID=${PARTUUID_2}\2|" "${MNTPATH}/cmdline.txt"
  Print_Style "cmdline.txt written ..." "$NORMAL"
  echo '# Enable the PCIe External connector' >> "${MNTPATH}/config.txt"
  echo 'dtparam=pciex1' >> "${MNTPATH}/config.txt"
  echo "" >> "${MNTPATH}/config.txt"
  echo '# Force Gen 3.0 speeds' >> "${MNTPATH}/config.txt"
  echo 'dtparam=pciex1_gen=3' >> "${MNTPATH}/config.txt"
  Print_Style "config.txt written ..." "$NORMAL" 
  umntpart
  mntpart "${DEVICE_P}2" "ROOT"
  sed -i "/^[[:space:]]*#/!s|^\S\+\(\s\+/boot\S*\s\+vfat\s\+.*\)$|PARTUUID=${PARTUUID_1}\1|" "${MNTPATH}/etc/fstab"
  sed -i "/^[[:space:]]*#/!s|^\S\+\(\s\+/\s\+.*\)$|PARTUUID=${PARTUUID_2}\1|" "${MNTPATH}/etc/fstab"
  Print_Style "fstab written ..." "$NORMAL"
  if [[ "${FIRSTBOOT}" = "TRUE" ]]; then
	#Firstboot resize
	rm "${MNTPATH}/etc/init.d/resize2fs_once"
	rm "${MNTPATH}/etc/rc3.d/S01resize2fs_once"
	Print_Style "'resize2fs_once' removed from init.d and rc3.d ..." "$NORMAL"
	#Manipulate init_resize.sh
	sed -i 's/check_variables () {/check_variables_old () {/' "${MNTPATH}/usr/lib/raspi-config/init_resize.sh"
	sed -i '3i check_variables () {'\\n'  FAIL_REASON=\"GPT Drive detected\"'\\n'  return 1'\\n'}'\\n'' "${MNTPATH}/usr/lib/raspi-config/init_resize.sh"
	Print_Style "File 'init_resize.sh' patched ..." "$NORMAL"
	#Patch firstboot
	sed -i 's/  whiptail --infobox \"Fix PARTUUID...\" 20 60/  /' "${MNTPATH}/usr/lib/raspberrypi-sys-mods/firstboot"
	sed -i 's/  fix_partuuid/  /' "${MNTPATH}/usr/lib/raspberrypi-sys-mods/firstboot"
	Print_Style "File 'firstboot' patched ..." "$NORMAL"
  fi
  umntpart
  Print_Style "Finished ..." "$MAGENTA"
else
  Print_Style "Finished, filesystem is already expanded ..." "$MAGENTA"
fi
