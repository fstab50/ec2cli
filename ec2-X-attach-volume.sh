#!/bin/bash
#
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  Shortcut for mounting of vols via user input                 |
#  Name:     ec2-X-attach-volume.sh                                       |
#  Location: $EC2_REPO                                                    |
#  Requires: awscli, awk, writable location                               |
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

#  FUTURE
#	- Error trapping/handling when attaching a vol attached to another instance
#	- Add ability to detach a volume
# 	- Add ability to delete a volume
#

# <-- start -->

# set vars
BOLD=`tput bold`
UNBOLD=`tput sgr0`

# functions
indent18() { sed 's/^/                  /'; }

echo -e "\n"

#
#------------ choose volume ----------------------------------------------
#

echo -e "\n${BOLD}Volume choices: ${UNBOLD}$AWS_DEFAULT_REGION\n" | indent18
sh $EC2_REPO/ec2-qv-volumes.sh > .text-output0.tmp
grep "vol-" .text-output0.tmp > .text-output1.tmp 

# Use built-in IFS to read in all lines in tmp file
IFS=$'\n' read -d '' -r -a VOLUMES < .text-output1.tmp

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
#
# header
echo -e "\n     VolumeID      GB  State     Attached  InstanceId  VolType   Avail-Zone  Description"
echo -e "     ------------  --  --------  --------  ----------  --------  ----------  ----------------------------"

# values
awk  '{ printf "%-4s %-13s %-3s %-9s %-9s %-11s %-9s %-11s %-2s %-2s %-2s %-2s \n", \
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12}' .arrayoutput.tmp

# Enter control structure to get user selection and validate
VALID=0 # set loop break

while [ $VALID -eq 0 ]
do
	# read volume choice in from user
	echo ""
	read -p "Enter # of choice or hit return for default [0]: " CHOICE
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

# assign volume to choice

if [ -z "$CHOICE" ]
then
       	# CHOICE is blank, assign to default
        CHOICE=0
fi

tmpVOLID=${VOLUMES[$CHOICE]}
VOLID=$(echo $tmpVOLID | cut -c 1-12)
echo "Volume "$VOLID" chosen."

# clean up
rm .text-output0.tmp
rm .text-output1.tmp
rm .arrayoutput.tmp

#
# ------------ choose instance -------------------------------------------
#

echo -e "\n${BOLD}EC2 Instance choices: ${UNBOLD}$AWS_DEFAULT_REGION\n" | indent18
sh $EC2_REPO/ec2-qv-instances.sh > .text-output0.tmp
grep "i-" .text-output0.tmp > .text-output1.tmp

# Use built-in IFS to read in all lines in tmp file
IFS=$'\n' read -d '' -r -a INSTANCES < .text-output1.tmp

# array max length
MAXCT=${#INSTANCES[*]} # keep in mind, IFS starts array index at 0

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
echo -e "\n     InstanceId    Type     State    SecurityGroup    Root-Volume     Version"
echo -e "     ----------- ---------  -------  --------------   ------------   ---------" 

# values
awk  '{ printf "%-4s %-11s %-10s %-8s %-16s %-14s %-9s \n", \
	$1, $2, $3, $4, $5, $6, $7}' .arrayoutput.tmp

# Enter control structure to get user selection and validate
VALID=0 # set loop break

while [ $VALID -eq 0 ]
do
        # read volume choice in from user
        echo ""
        read -p "Enter # of choice or hit return for default [0]: " CHOICE
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

# assign volume to choice

if [ -z "$CHOICE" ]
then
        # CHOICE is blank, assign to default
        CHOICE=0
fi

tmpINSTANCEID=${INSTANCES[$CHOICE]}
INSTANCEID=$(echo $tmpINSTANCEID | cut -c 1-10)
echo -e "Instance "$INSTANCEID" chosen.\n"

# clean up
rm .text-output0.tmp
rm .text-output1.tmp
rm .arrayoutput.tmp


#exit 0  # BREAK INSERTED FOR TESTING

#
# choose device ###########################################################
#

read -p  "Enter device to mount to [/dev/sda1]:  " DEVICE
DEFAULTDEV="/dev/sda1"

if [ -z "$DEVICE" ]
then
  DEVICE=$DEFAULTDEV
else
  DEVICE=$DEVICE
fi

# go
echo -e "\nAttaching volume.....\n"
aws ec2 attach-volume \
	--volume-id $VOLID \
	--instance-id $INSTANCEID \
	--device $DEVICE \
	--output table

# test output area
#echo "Summary Output:"
#echo "Volume to attach: "$VOLID
#echo "To instance: "$INSTANCEID
#echo "Attached as device: "$DEVICE
