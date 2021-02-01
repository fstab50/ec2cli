#!/bin/bash
#
# Name:   motd.sh
# Usage:  this script must be located at /etc/profile.d/motd.sh
# Requires: figlet
#

indent02() { sed 's/^/  /'; }

# print normal motd
HOSTNAME=`uname -n`
KERNEL=`uname -r`
CPU=$(cat /proc/cpuinfo | grep 'model name' | tail -1 | cut -c 14-60)
ARCH=`uname -m`
UTIME=`uptime | sed -e 's/ [0-9:]* up />/' -e 's/,.*//'`
ID=`grep VERSION_ID /etc/os-release | awk -F '=' '{print $2}' | cut -c 2-3 | rev | cut -c 2-3 | rev`

# set colors
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
purple=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
reset=$(tput sgr0)

# bold codes
BOLD=`tput bold`
UNBOLD=`tput sgr0`

echo ""
echo -e "${reset}===============================================================${reset}" | indent02
echo ""
echo  "       $W HOST   : ${BOLD}${blue}Docker $HOSTNAME${reset}${UNBOLD} "
echo  "       $R ARCH   : ${cyan}$ARCH${reset}        "
echo  "       $R KERNEL : ${cyan}$KERNEL${reset}      "
echo  "       $R CPU    : ${cyan}$CPU${reset}         "
echo  "       $R Uptime : ${cyan}$UTIME${reset}       "
echo -e "${red}"
echo -e "       "CentOS"   "$ID| figlet -f shadow
echo  -e "${reset}===============================================================${reset}" | indent02
echo ""



exit 0
