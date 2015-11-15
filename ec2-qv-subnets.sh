#!/bin/bash
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  QuickView of all subnets in the AWS acct                     |
#	     indicated by $AWS_ACCESS_KEY                                 |
#  Name:     ec2-qv-subnets.sh                                            |
#  Location: $EC2_REPO                                                    |
#  Requires: awscli, awk, sed, writable dir                               |
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

# FUTURE
#	-

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
printf "\n\n${BOLD}SUBNETS FOR REGION:${UNBOLD} $AWS_DEFAULT_REGION\n\n" | indent18

# test default shell, format change if debian default (dash)
case "$SHELL" in
  *bash*)
        # shell appears to be bash 
        echo -ne "\nName SubnetId Public CIDR-Block #IPs AvailZone Default\n \
        ------------- --------------- ------ --------------- ---- ---------- -------\n" > .ec2-qv.tmp
  ;;

  *)
        # shell other than bash 
        echo "\nDefault shell appears to be non-bash. Please rerun with bash. Exiting. Code $E_BADSHELL\n"
        exit $E_BADSHELL
  ;;
esac

# output from aws
aws ec2 describe-subnets \
	--output text \
	--query "Subnets[*]. \
		[Tags[0].Value, \
		SubnetId, \
		MapPublicIpOnLaunch, \
		CidrBlock, \
		AvailableIpAddressCount, \
		AvailabilityZone, \
		DefaultForAz]" | sort -k +4n >> .ec2-qv.tmp


# print and format output
#
# Note: Since awk is looking for blank space as delimiter, we allow spaces
#       in the description field by telling awk these are 2 char columns.
#       Description field containing up to 7 strings separated by a single 
#       space will be printed via below awk statement (last 7 columns).
#
awk  '{ printf "%-15s %-17s %-7s %-16s %-6s %-12s %-2s \n", \
        $1, $2, $3, $4, $5, $6, $7}' .ec2-qv.tmp


# print footer
echo " "

# clean up
rm .ec2-qv.tmp

# <-- end -->

exit 0
