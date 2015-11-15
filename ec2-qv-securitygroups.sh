#!/bin/bash
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  QuickView of all ec2 security groups in the AWS acct         |
#	     indicated by $AWS_ACCESS_KEY                                 |
#  Name:     ec2-qv-securitygroups.sh                                     |
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
#  Log:  N/A                                                              |
#                                                                         |
#_________________________________________________________________________|

#
# < -- Start -->
#
# print header
# set vars
BOLD=`tput bold`
UNBOLD=`tput sgr0`
E_BADSHELL=7            # exit code if incorrect shell 

# functions
indent18() { sed 's/^/                  /'; }

# print region identifier
printf "\n\n${BOLD}SECURITY GROUPS:${UNBOLD} $AWS_DEFAULT_REGION\n\n" | indent18

# test default shell, format change if debian default (dash)
case "$SHELL" in
  *bash*)
        # shell appears to be bash 
        echo -ne "\nGroupName Group-Id Ports Ports CidrIp VpcId Description\n \
        --------------- ----------- ----- ----- ----------------- ------------ \
        --------------------------------\n" > .ec2-qv-securitygroups.tmp
  ;;

  *)
        # shell other than bash 
	echo "\nDefault shell appears to be non-bash. Please rerun with bash. Exiting. Code $E_BADSHELL\n"
        exit $E_BADSHELL
  ;;
esac

# output from aws
aws ec2 describe-security-groups \
	--output text \
	--query "SecurityGroups[*]. \
		[GroupName, \
		GroupId, \
		IpPermissions[0].FromPort, \
		IpPermissions[0].ToPort, \
		IpPermissions[0].IpRanges[0].CidrIp, \
		VpcId, \
		Tags[0].Value]" \
>> .ec2-qv-securitygroups.tmp


# print and format output
#
# Note: Since awk is looking for blank space as delimiter, we allow spaces
#       in the description field by telling awk these are 2 char columns.
#       Description field containing up to 7 strings separated by a single 
#       space will be printed via below awk statement (last 7 columns).
#
awk  '{ printf "%-18s %-13s %-6s %-7s %-19s %-14s %-2s \n", \
        $1, $2, $3, $4, $5, $6, $7}' .ec2-qv-securitygroups.tmp


# print footer
echo " "

# clean up
rm .ec2-qv-securitygroups.tmp

# <-- end -->

exit 0
