#!/bin/bash

#
# Name: 30-banner
# Location: /etc/update-motd.d/
# Requires: update-motd, Amazon Linux AMI
# Usage: script must be located at /etc/update-motd.d \
# and replace existing 30-banner.  Must be lowest # file in location.
#

# vars
HOSTNAME=`uname -n`
REGION=$(sh $EC2_BASE/ec2-az-zone-location.sh 2>/dev/null)
KERNEL=`uname -r`
CPU=$(cat /proc/cpuinfo | grep 'model name' | tail -1 | cut -c 14-60)
ARCH=`uname -m`
UTIME=`uptime | sed -e 's/ [0-9:]* up />/' -e 's/,.*//'`
#

# Uncomment for different colors (term dependent)
#W="\033[01;37m"
#B="\033[01;34m"
#R="\033[01;31m"
#X="\033[00;37m"

echo "$R==============================================================="
echo ""
echo  "       $W Welcome to $HOSTNAME                 "
echo  "       $W REGION $W: $REGION                   "
echo  "        ------"
echo  "       $R ARCH   $W: $ARCH                     "
echo  "       $R KERNEL $W: $KERNEL                   "
echo  "       $R CPU    $W: $CPU                      "
echo  "       $R Uptime $W: $UTIME                    "
echo ""
echo  "         __|  __|_  )                          "
echo  "         _|  (     /   Amazon Linux AMI        "
echo  "        ___|\___|___|                          "
echo ""
echo  "$R=============================================================="
echo ""
