#!/bin/bash
#
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  Quickview of all AMI machine images assicated with acct      |
#            indicated by $AWS_ACCESS_KEY                                 |
#  Name:     ec2-qv-AMIs.sh                                               |
#  Location: $EC2_REPO                                                    |
#  Requires: awscli, awk, sed, writable dir                               |
#  Environment Variables (required, global):                              |
#       EC2_BASE                                                          |
#       EC2_HOME                                                          |
#       AWS_ACCESS_KEY                                                    |
#       AWS_SECRET_KEY                                                    |
#       AWS_DEFAULT_REGION                                                |
#  User:     $USER                                                        |
#  Output:   CLI                                                          |
#  Error:    stderr                                                       |
#                                                                         |
#_________________________________________________________________________|

#
# < -- Start -->
#

# set vars
BOLD=`tput bold`	# bold text begin marker
UNBOLD=`tput sgr0`	# bold text end marker
E_BADSHELL=7		# exit code if incorrect shell detected

# test default shell, fail if debian default (dash)
case "$SHELL" in
  *dash*)
        # shell is ubuntu default, dash
        echo "\nDefault shell appears to be dash. Please rerun with bash. Exiting. Code $E_BADSHELL\n"
        exit $E_BADSHELL
  ;;
esac

# functions
indent18() { sed 's/^/                  /'; }

# print region identifier
echo ""
printf "\n${BOLD}AMAZON MACHINE IMAGES :${UNBOLD} $AWS_DEFAULT_REGION\n" | indent18
echo ""


# print header
echo -ne "\nAMI-id Type Virtual. Drv RootDev SnapshotId Description\n \
        ------------ ------- ----------- --- --------- ------------- \
        --------------------------------------\n" > .ec2-qv-amis.tmp

# output from aws
aws ec2 describe-images \
	--owner self \
	--output text \
	--query "Images[*]. \
		[ImageId, \
		ImageType, \
		VirtualizationType, \
		RootDeviceType, \
		RootDeviceName, \
		BlockDeviceMappings[0].Ebs.SnapshotId, \
		Tags[0].Value]" \
>> .ec2-qv-amis.tmp

# print and format output
#
# Note: Since awk is looking for blank space as delimiter, we allow spaces
#       in the description field by telling awk these are 2 char columns.
#       Description field containing up to 7 strings separated by a single 
#       space will be printed via below awk statement (last 7 columns).
#
awk  '{ printf "%-13s %-8s %-12s %-4s %-10s %-14s %-2s %-2s %-2s %-2s \n", \
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10}' .ec2-qv-amis.tmp

# print footer
echo " "

# clean up
rm .ec2-qv-amis.tmp

# <-- end -->

exit 0
