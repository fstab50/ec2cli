#!/bin/bash
#
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  CLI utility for starting and connecting to ec2 instances     |
#  Name:     ec2-X-start-instance.sh                                      |
#  Location: $EC2_REPO                                                    |
#  Requires: awscli, jq (JSON parser)                                     |
#  Environment Variables (required, global):                              |
#       EC2_BASE                                                          |
#       EC2_HOME                                                          |
#	EC2_REPO                                                          |
#       AWS_ACCESS_KEY                                                    |
#       AWS_SECRET_KEY                                                    |
#       AWS_DEFAULT_REGION                                                |
#	SSH_KEYS: location of AWS key pairs (.pem files)                  |
#  User:     $USER                                                        |
#  Out:      CLI                                                          |
#  Error:    stderr                                                       |
#                                                                         |
#_________________________________________________________________________|

# Future Enhancements:
#       - Test for Linux EC2 instance start (this script ONLY good for Linux
#	  since ssh login at end 
#     

# < -- Start -->

echo -e "\n"

# vars
NOW=$(date)
PROGRESSTXT="EC2 Instance Starting Up.  Please wait... "
BOLD=`tput bold`
UNBOLD=`tput sgr0`
E_BADSHELL=7                    # exit code if incorrect shell
E_NETWORK_ACCSS=8               # exit code if no network access from current location
E_USER_CANCEL=9                 # exit code if user cancel, no instance start

# set fs pointer to writeable temp location in memory
if [ "$(df /run | awk '{print $1, $6}' | grep tmpfs 2>/dev/null)" ]
then
        TMPDIR="/dev/shm"
        cd $TMPDIR     
else
        TMPDIR="/tmp"
        cd $TMPDIR 
fi

#
# functions -------------------------------------------------------------------
#

# formatting
indent18() { sed 's/^/                  /'; }

# spinner progress marker function
spinner()
{
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r$PROGRESSTXT[%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    #printf "    \b\b\b\b"
}

#
# validate shell env ----------------------------------------------------------
#

# test default shell, fail if not bash
if [ ! -n "$BASH" ]
  then
        # shell other than bash 
        echo "\nDefault shell appears to be something other than bash. Please rerun with bash. Exiting. Code $E_BADSHELL\n"
        exit $E_BADSHELL
fi

#
# choose instance ----------------------------------------------------------
#

# <-- start -->

echo -e "\n${BOLD}Available Instances: ${UNBOLD}$AWS_DEFAULT_REGION\n" | indent18
    aws ec2 describe-instances \
            --output text \
            --query "Reservations[*].Instances[*]. \
            [InstanceId, \
                    InstanceType, \
                    State.Name, \
                    SecurityGroups[0].GroupName, \
                    BlockDeviceMappings[0].Ebs.VolumeId, \
                    PublicIpAddress, \
                    Tags[1].Value]" \
    >> .text-output1.tmp


# Use built-in IFS to read in all lines in tmp file
IFS=$'\n' read -d '' -r -a INSTANCES < .text-output1.tmp

# array max length
MAXCT=${#INSTANCES[*]} # IFS starts array index at 0

# load output choice array
i=0
while (( i < $MAXCT ))
do
        echo "($i): ""${INSTANCES[$i]}" >> .arrayoutput.tmp
        i=$(( $i+1 ))
done

# display choices from array
#
# header
echo -e "\n     InstanceID    Type     State   SecurityGroup     Root-Volume      PublicIP       Description"
echo -e "     ----------  ---------  ------- --------------    ------------   --------------   -------------------------"

# values
awk  '{ printf "%-4s %-11s %-10s %-8s %-16s %-14s %-16s %-2s %-2s %-2s %-2s \n", \
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11}' .arrayoutput.tmp

# clean up
rm .text-output1.tmp .arrayoutput.tmp

#
# get user input while checking type and range
#
VALID=0    # set loop break

while [ $VALID -eq 0 ]
do
        # read choice in from user
        echo ""
        read -p "Enter # of choice or hit return for default [quit]: " CHOICE
        echo ""

        # assign instance to choice
        if [[ -n ${CHOICE//[0-$(( $MAXCT-1 ))]/} ]]
        then
                # invalid user entry
                echo "You must enter an integer number between 0 and $(( $MAXCT-1 ))."
        else
                if [ -z "$CHOICE" ]
                then
                        # CHOICE is blank, assign default
                        exit $E_USER_CANCEL
                else
                        # valid user entry, exit loop
                        VALID=1
                fi
        fi
done

tmpID=${INSTANCES[$CHOICE]}
TARGET=$(echo $tmpID | cut -c 1-10)
echo "You chose to start instance $TARGET."

#
# network access check -------------------------------------------------
#

echo -e "\nChecking Network Access.  Please wait ..."

# retrieve secuirty group(s) of selected ec2 instance
aws ec2 describe-instances \
        --output text \
        --instance-id $TARGET \
        --query 'Reservations[].Instances[].SecurityGroups[*].GroupId' > .secgrp-ids.tmp 

# discover local ip
dig +short myip.opendns.com @resolver1.opendns.com > .myip.tmp
MYIP=$(cat .myip.tmp)

# query ip's from assigned security group
aws ec2 describe-security-groups \
        --group-ids $(cat .secgrp-ids.tmp) \
        --output text \
        --query 'SecurityGroups[].[IpPermissions[].IpRanges[*].CidrIp]' > .output.tmp


if grep "$MYIP" .output.tmp > /dev/null
then
        # Access validated
        echo -e "\nNetwork access ok, proceeding.\n"

        # clean up
        rm .myip.tmp .output.tmp .secgrp-ids.tmp
else
        # No access from current login client location
        echo -e "\nNo Network access from this location.  Please update security group.\n"
        
        # clean up
        rm .myip.tmp .output.tmp .secgrp-ids.tmp
        
        exit $E_NETWORK_ACCESS
fi

#
# start instance ---------------------------------------------------------
#

# start remote instance
aws ec2 start-instances --instance-ids $TARGET | jq . 

# wait for instance to start, return after
aws ec2 wait instance-running --instance-ids $TARGET &

# call function to show on screen while wait
spinner

# login delay: loop for i seconds, display counter
i=10    # count in seconds
echo -e "\n "

while (( i > 0 ))
do
        printf "\rInstance available in: ""$i"" seconds"
        sleep 1
        i=$(( i-1 ))
done
echo -e "\n\nAuthenticating...\n"


# discover public ip assignment
IPADDRESS=$(aws ec2 describe-instances \
        --output text \
        --instance-id $TARGET \
        --query 'Reservations[].Instances[].[PublicIpAddress]') 

# discover required access key
KEY=$(aws ec2 describe-instances \
        --output text \
        --instance-id $TARGET \
        --query 'Reservations[].Instances[].[KeyName]')".pem" 

# login
ssh -i $SSH_KEYS/$KEY ec2-user@$IPADDRESS

#
# <-- end --->

exit 0

