#!/bin/bash
#
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  set correct hostname when ec2 instances (re)started          |
#  Name:     ec2-hostname.sh                                              |
#  Location: $EC2_BASE                                                    |
#  Requires: awscli, api-tools                                            |
#  Environment Variables (required, global):                              |
#   	EC2_BASE                                                          |
#       EC2_HOME                                                          |
#       AWS_DEFAULT_REGION                                                |
#  User:     init process (root)                                          |
#  StdOut:   log                                                          |
#  Error:    stderr                                                       |
#  Log:      /var/log/messages                                            |
#                                                                         |
#_________________________________________________________________________|
#
#  Note:
#  This must be called upon startup by the init process.  This can be 
#  done multiple ways; however, suggest call in rc.local
#

# <-- start -->

# get internal and external (public) hostnames
INTERNALNAME=$(curl -s http://instance-data.us-west-2.compute.internal/latest/meta-data/hostname)
EXTERNALNAME=$(curl -s http://instance-data.us-west-2.compute.internal/latest/meta-data/public-hostname)

# get ip assigned by aws
IPV4=$(/usr/bin/curl -s http://instance-data.us-west-2.compute.internal/latest/meta-data/public-ipv4)

# Set the host name
hostname $INTERNALNAME
echo $INTERNALNAME > /etc/hostname

# update /etc/sysconfig/network with new internal name
OLDNAME=$(grep HOSTNAME /etc/sysconfig/network)
NEWNAME="HOSTNAME="$INTERNALNAME
sed -i "s/$OLDNAME/$NEWNAME/g" /etc/sysconfig/network

# Add fqdn to hosts file
cat<<EOF > /etc/hosts
# This file automatically genreated by ec2-hostname.sh
127.0.0.1 localhost
$IPV4  $EXTERNALNAME $INTERNALNAME

# IPv6 hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF
