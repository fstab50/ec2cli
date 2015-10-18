#!/bin/bash
#
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  Utility for taking snapshots of EBS volumes                  |
#  Name:     ec2-X-take-snapshot.sh                                       |
#  Location: $EC2_REPO                                                    |
#  Requires: awscli, jq (JSON parser)                                     |
#  Environment Variables (required, global):                              |
#       EC2_BASE                                                          |
#       EC2_HOME                                                          |
#	EC2_REPO                                                          |
#       AWS_ACCESS_KEY                                                    |
#       AWS_SECRET_KEY                                                    |
#       AWS_DEFAULT_REGION                                                |
#  User:     $USER                                                        |
#  Out:      CLI                                                          |
#  Error:    stderr                                                       |
#                                                                         |
#_________________________________________________________________________|

# FUTURE:
#	- Display volumes prepended with numerical choice values per ec2-X-attach-volume.sh
#       - Modify spinner() to include display of snap progress % with each iteration of internal while loop
#	  This grabs % complete if snapshot-id is known:
#         $  aws ec2 describe-snapshots \
#			--owner self \
#			--output text \
#			--query 'Snapshots[*].[Progress]' \
#			--filters Name="snapshot-id",Values=snap-d849098d
#       - Ability to take snaps of multiple volumes 
#       - Error trapping & handling for all user entered data
#     

# < -- Start -->

echo -e "\n"

# vars
NOW="$(date +"%Y-%m-%d")"
BOLD=`tput bold`
UNBOLD=`tput sgr0`
PROGRESSMSG="EC2 Snapshot Started.  Please wait... "

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
# choose volume ----------------------------------------------------------
#

# display volumes associated with default zone for user's AWS account
sh $EC2_REPO/ec2-qv-volumes.sh    # includes header

echo -e "\nEnter the # of the volume of which you wish to take a snapshot."

# collect list of all current AWS Regions globally:
aws ec2 describe-volumes \
        --output text \
        --query 'Volumes[*].[VolumeId]' \
>> .ec2-X-take-snapshot.tmp

# Use built-in IFS to read in all lines in tmp file
IFS=$'\n' read -d '' -r -a VOLUMES < .ec2-X-take-snapshot.tmp

# array max length
MAXCT=${#VOLUMES[*]} # keep in mind, IFS starts array index at 0

# load output choice array
i=0  
while (( i < $MAXCT ))
do
        echo "($i): ""${VOLUMES[$i]}" >> .arrayoutput.tmp
        i=$(( $i+1 ))
done

# display choices from array
cat .arrayoutput.tmp

# read volume choice in from user
echo ""
read -p "Enter # of choice or hit return for default [0]: " CHOICE
echo ""

# assign volume to choice

if [ -z "$CHOICE" ]
then
        # CHOICE is blank, assign default
        CHOICE=0
fi

VOLID=${VOLUMES[$CHOICE]}
echo "You chose to create a snapshot of Volume $VOLID."

# clean up
rm .ec2-X-take-snapshot.tmp
rm .arrayoutput.tmp

#
# create snapshot ---------------------------------------------------------
#

# description = concatenate volume date + Name tag
NAMETAG=$(aws ec2 describe-volumes \
		--volume-id  $VOLID \
		--query 'Volumes[*].[Tags[0].Value]' \
		--output text)

DESCRIPTION=$NOW", ""$NAMETAG"

# start snapshot
aws ec2 create-snapshot --volume-id $VOLID --description "$DESCRIPTION" | jq . 

# progress meter while wait, inspect snapshot for VOLID
aws ec2 wait snapshot-completed --filters Name="volume-id",Values=$VOLID &

# call function to show on screen while wait
spinner  

# <-- end -->

exit 0
