#!/bin/bash
#
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  Starts remote desktop instance and logs in via rdp           |
#  Name:     ec2-X-rdp-desktop.sh                                         |
#  Location: $EC2_REPO                                                    |
#  Requires: awscli, jq (JSON parser), windows EC2 with rdp enabled       |
#  Environment Variables (required, global):                              |
#       EC2_BASE                                                          |
#       EC2_HOME                                                          |
#       AWS_ACCESS_KEY                                                    |
#       AWS_SECRET_KEY                                                    |
#       AWS_DEFAULT_REGION                                                |
#	REMOTE_RDP_PASSWD                                                 |
#  User:     $USER                                                        |
#  StdOut:   CLI                                                          |
#  Error:    stderr                                                       |
#  Log:	     N/A                                                          |
#                                                                         |
#_________________________________________________________________________|
#
# FUTURE log
#	- add failure modes & error handling
#	- detect deps (rdesktop, awscli, jq)
#	- Detect screen resolution instead of hardocded array values
#	  when choosing RDP session window size
#	- Validate current client IP is permitted in RDP sec group
#
# Definitions:
#	- EC2 m4.large instance is RDP target
#	- OS is Windows Server 2008 R2
#	- Data volume is encrypted [D:\]
#	- Licensed copy of Office 2013 installed

#
# <-- start -->
#

# vars
TARGET=$RDP_DESKTOP     # instance to be started 
BOLD=`tput bold`	# formatting
UNBOLD=`tput sgr0`	# formatting
SIZE="90%"    		# default rdp window size (% of local desktop resolution)
E_BADSHELL=7		# exit code if incorrect shell detected
E_NETWORK_ACCSS=8	# exit code if no network access to target instance
PROGRESSMSG="EC2 instance starting.  Please wait... "


# test default shell, fail if debian default (dash)
case "$SHELL" in
  *dash*)
        # shell is ubuntu default, dash
        echo "\nDefault shell appears to be dash. Please rerun with bash. Exiting. Code $E_BADSHELL\n"
        exit $E_BADSHELL
  ;;
esac

# spinner progress marker function
spinner()
{
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r$PROGRESSMSG[%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    #printf "    \b\b\b\b"
}

#
# network access check -------------------------------------------------
#

echo -e "\nChecking Network Access.  Please wait ..."

# grab myip
dig +short myip.opendns.com @resolver1.opendns.com > .myip.tmp
MYIP=$(cat .myip.tmp)

# query ip's from assigned security group
aws ec2 describe-security-groups \
        --group-names security-grpRDP \
        --output text \
        --query 'SecurityGroups[].[IpPermissions[].IpRanges[*].CidrIp]' > .output.tmp

if grep "$MYIP" .output.tmp > /dev/null
then
        echo -e "\nNetwork access ok, proceeding.\n"
        rm .myip.tmp .output.tmp   # clean up
else
        echo -e "\nNo Network access from this location.  Please update security group.\n"
        rm .myip.tmp .output.tmp   # clean up
        exit $E_NETWORK_ACCESS
fi

#
# Init -----------------------------------------------------------------
#

# start remote desktop instance
aws ec2 start-instances --instance-ids $TARGET | jq .

# wait for instance to start, return after
aws ec2 wait instance-running --instance-ids $TARGET &

# call function to show on screen while wait
spinner     

# get public hostname assignment
HOSTNAME=$(aws ec2 describe-instances \
	--instance-id $TARGET \
        --output text \
        --query 'Reservations[*].Instances[*].[PublicDnsName]')

# test OS and start the correct rdp window size
if [ -f /etc/debian_version ]; then
        # Debian-based, my laptop 

	# load array with choices
	RDP_SIZE[0]="1366x768"
	RDP_SIZE[1]="1400x860"
	RDP_SIZE[2]="1900x1000"
	MAXCT=${#RDP_SIZE[*]}

	i=0    # counter
	while (( i < $MAXCT ))
	do
        	echo "($i): ""${RDP_SIZE[$i]}"  >> .type.tmp
        	i=$(( $i+1 ))
	done

	# print choices
	echo -e "\n${BOLD}Select an RDP Session Window Size:${UNBOLD}\n"
	awk -F "  " '{ printf "%-4s %-20s \n", $1, $2}' .type.tmp

	# get user input while checking type and range
	VALID=0    # set loop break

	while [ $VALID -eq 0 ]
	do
        	# read instance choice in from user
	        echo ""
        	read -p "Enter desired RDP session window size [1]: " CHOICE
	        echo ""

        	if [[ -n ${CHOICE//[0-$(( $MAXCT-1 ))]/} ]]
        	then
			# invalid user entry
                	echo "You must enter an integer number between 0 and $(( $MAXCT-1 ))."
        	else
			# valid user entry, exit loop
                	VALID=1
        	fi
	done

	if [ -z "$CHOICE" ]
	then
        	# CHOICE is blank, default chosen
	        CHOICE=1
	fi

	# set type
	SIZE=${RDP_SIZE[$CHOICE]}
	echo -e "You Selected: "$SIZE"\n"
	echo -e "Starting RDP Session with selected window size.\n"

        # clean up
        rm ./.type.tmp
fi
	# both debian & RH variants
	# Start rdp desktop session
	rdesktop -u Administrator -p $REMOTE_RDP_PASSWD -g $SIZE -a 24 $HOSTNAME & 


# <-- end -->

exit 0
