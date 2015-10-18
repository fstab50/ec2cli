#!/bin/bash
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  QuickView of all VPCs in the AWS acct                        |
#	     indicated by $AWS_ACCESS_KEY                                 |
#  Name:     ec2-qv-vpc.sh                                                |
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
#	- Add: display subnets after initial vpc display using describe-subnets
#	-
#
# < -- Start -->
#

# set vars
BOLD=`tput bold`
UNBOLD=`tput sgr0`

# functions
indent18() { sed 's/^/                  /'; }

# print region identifier
printf "\n\n${BOLD}VPCs FOR REGION:${UNBOLD} $AWS_DEFAULT_REGION\n\n" | indent18

# test default shell, format change if debian default (dash)
case "$SHELL" in
  *dash*)
        # shell is ubuntu default, dash
        echo "\nVpcId State Tenancy CIDR-Block Default\n \
        ------------ --------- ------- ------------------ -------" > .ec2-qv-vpc.tmp
  ;;

  *bash*)
        # shell appears to be bash 
        echo -ne "\nVpcId State Tenancy CIDR-Block Default\n \
        ------------ --------- ------- ------------------ -------\n" > .ec2-qv-vpc.tmp
  ;;
esac

#
# output from aws
#
aws ec2 describe-vpcs \
	--output text \
	--query 'Vpcs[*]. \
		[VpcId, \
		State, \
		InstanceTenancy, \
		CidrBlock, \
		IsDefault]' | sort -k +4n \
>> .ec2-qv-vpc.tmp


# print and format output
#
# Note: Since awk is looking for blank space as delimiter, we allow spaces
#       in the description field by telling awk these are 2 char columns.
#       Description field containing up to 7 strings separated by a single 
#       space will be printed via below awk statement (last 7 columns).
#
awk  '{ printf "%-14s %-10s %-9s %-20s %-9s \n", \
        $1, $2, $3, $4, $5}' .ec2-qv-vpc.tmp


# print footer
echo " "

# clean up
rm .ec2-qv-vpc.tmp

# <-- end -->

exit 0
