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

# functions
indent18() { sed 's/^/                  /'; }

# print region identifier
printf "\n\n${BOLD}EBS VOLUMES:${UNBOLD} $AWS_DEFAULT_REGION\n\n" | indent18


# test default shell, format change if debian default (dash)
case "$SHELL" in
  *bash*)
        # shell appears to be bash 
	echo -ne "\nVolume-Id GB State Attached InstanceId VolType Avail-Zone Description\n \
        ------------ -- -------- -------- ---------- -------- ---------- \
        ---------------------------------------\n" > .ec2-qv-volumes.tmp
  ;;

  *)
        # shell other than bash 
        echo "\nDefault shell appears to be non-bash. Please rerun with bash. Exiting. Code $E_BADSHELL\n"
        exit $E_BADSHELL
  ;;
esac

# output from aws
aws ec2 describe-volumes \
	--output text \
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

# print and format output
#
# Note: Since awk is looking for blank space as delimiter, we allow spaces
#       in the description field by telling awk these are 2 char columns.
#       Description field containing up to 7 strings separated by a single 
#       space will be printed via below awk statement (last 7 columns).
#
awk  '{ printf "%-13s %-3s %-9s %-9s %-11s %-9s %-11s %-2s %-2s %-2s %-2s %-2s \n", \
	$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12}' .ec2-qv-volumes.tmp

# print footer
echo " "

# clean up
rm .ec2-qv-volumes.tmp

exit 0
