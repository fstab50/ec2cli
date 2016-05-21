#!/bin/bash
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  QuickView of ec2 EBS volumes in table form                   |
#  Name:     ec2-qv-volumes.sh                                            |
#  Location: $EC2_REPO                                                    |
#  Requires: awscli, awk, sed, bash, writable dir                         |
#  Environment Variables (required, global):                              |
#       EC2_BASE                                                          |
#       EC2_HOME                                                          |
#       AWS_ACCESS_KEY                                                    |
#       AWS_SECRET_KEY                                                    |
#       AWS_DEFAULT_REGION                                                |
#  User:     $USER                                                        |
#  Out:      CLI                                                          |
#  Error:    stderr                                                       |
#  Log:      N/A                                                          |
#                                                                         |
#_________________________________________________________________________|

#  FUTURE
#	- After display default aws region EBS vols, choose to display for 
#	  for other regions or exti
#	- Display a total for each EBS volume type (gp2, std, etc)
#

#
# < -- Start -->
#

# set vars
BOLD=`tput bold`
UNBOLD=`tput sgr0`
E_BADSHELL=7		# exit code if incorrect shell
E_BADARG=8                    # exit code if bad input parameter    
REGION=$AWS_DEFAULT_REGION    # set region from global env var

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
# functions  ------------------------------------------------------------------
#

indent02() { sed 's/^/  /'; }
indent10() { sed 's/^/          /'; }
indent18() { sed 's/^/                  /'; }

#
# Validate Shell  --------------------------------------------------------------
#

# test default shell, fail if not bash
if [ ! -n "$BASH" ]
  then
        # shell other than bash 
        echo "\nDefault shell appears to be something other than bash. \
                Please rerun with bash. Exiting. Code $E_BADSHELL\n"
        exit $E_BADSHELL
fi

#
# Alternative (non-default) Region Handling  -----------------------------------
#

if [ $1 ]
then
  	if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "--h" ]
  	then
    		# help menu requested
    		printf "\n  ${BOLD}Help Contents: ${UNBOLD}\n\n" 
    		echo -e "  [--help | -h] :  this menu"
    		echo -e "  [region code] :  EBS Volume details for specified alternate region"
    		echo -e "  [no arg]      :  EBS Volume details for region specified by AWS_DEFAULT_REGION env variable\n"
    		exit 0
  	fi
    
	# collect list of all current AWS Regions globally:
        aws ec2 describe-regions --output text --query 'Regions[*].[RegionName]' > .rawoutput.tmp

        if [ "$1" == "$(grep $1 .rawoutput.tmp 2>/dev/null)" ]
        then
                # non-default region specified
                REGION=$1
        else
                # exit, bad entry
                echo -e "\n  Parameter must be a valid AWS region code (example: ${BOLD}us-east-1${UNBOLD})"
                echo -e "  or ${BOLD}--help${UNBOLD} to request the help menu.  Exiting, error code "$E_BADARG"\n"

                # clean up and exit
                rm .rawoutput.tmp
                exit $E_BADARG
        fi

        rm .rawoutput.tmp    # clean up


fi

#
# End alt region --------------------------------------------------------------
#

# <-- start -->

# sum total size of all volumes (display in footer)
SUM=$(aws ec2 describe-volumes --region $REGION | jq -r '.Volumes | map(.Size) | add')

if [ $SUM == "null" ] || [ $SUM -eq 0 ]
then
        # print footer if no volumes found
        printf "\n\n** ${BOLD}0${UNBOLD} volumes in region [$REGION], total ${BOLD}0${UNBOLD} GB **\n\n\n" | indent10

else
	#
	# volumes found
	#

	# print region identifier
	printf "\n\n${BOLD}EBS VOLUMES${UNBOLD} : $REGION\n\n" | indent18

	# print header 
	echo -ne "\nVolume-Id GB State Attached InstanceId VolType Avail-Zone Description\n \
        	------------ -- -------- -------- ---------- -------- ---------- \
        	-----------------------------\n" > .ec2-qv-volumes.tmp
	
	#
	# output from aws
	#
	aws ec2 describe-volumes \
		--output text \
		--region $REGION \
		--query "Volumes[*]. \
			[VolumeId, \
			Size, \
			State, \
			Attachments[0].State,
			Attachments[0].InstanceId, \
			VolumeType, \
			AvailabilityZone, \
			Tags[0].Value]" \
	>> .ec2-qv-volumes.tmp

	# count total
	TOTAL=$(cat .ec2-qv-volumes.tmp | grep "vol-" | wc -l)

	# print and format output
	#
	# Note: Since awk is looking for blank space as delimiter, we allow spaces
	#
	awk  '{ printf "%-13s %-3s %-9s %-9s %-11s %-9s %-11s %-2s %-2s %-2s \n", \
		$1, $2, $3, $4, $5, $6, $7, $8, $9, $10}' .ec2-qv-volumes.tmp | indent02

	# print footer
	printf "\n\n${BOLD}$TOTAL${UNBOLD} volumes in region [$REGION], total "${BOLD}$SUM${UNBOLD}" GB\n\n\n" | indent10

	# clean up
	rm .ec2-qv-volumes.tmp
fi

# <-- end -->

exit 0
