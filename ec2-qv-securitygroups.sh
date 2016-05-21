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
    		echo -e "  [region code] :  Security Group details for specified alternate region"
    		echo -e "  [no arg]      :  Security Group details for region specified by AWS_DEFAULT_REGION env variable\n"
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

# print region identifier
printf "\n\n${BOLD}SECURITY GROUPS${UNBOLD} : $REGION\n\n" | indent18

# print header 
echo -ne "\nGroupName Group-Id Ports Ports CidrIp VpcId Description\n \
        ---------------- ----------- ----- ----- ----------------- ------------ \
        ---------------------------\n" > .ec2-qv-securitygroups.tmp

# output from aws
aws ec2 describe-security-groups \
	--output text \
  	--region $REGION \
	--query "SecurityGroups[*]. \
		[GroupName, \
		GroupId, \
		IpPermissions[0].FromPort, \
		IpPermissions[0].ToPort, \
		IpPermissions[0].IpRanges[0].CidrIp, \
		VpcId, \
		Tags[0].Value]" \
>> .ec2-qv-securitygroups.tmp

# count total
TOTAL=$(cat .ec2-qv-securitygroups.tmp | grep "sg-" | wc -l)

# print and format output
#
# Note: Since awk is looking for blank space as delimiter, we allow spaces
#       in the description field by telling awk these are 2 char columns.
#
awk  '{ printf "%-18s %-13s %-6s %-7s %-19s %-14s %-2s \n", \
        $1, $2, $3, $4, $5, $6, $7}' .ec2-qv-securitygroups.tmp | indent02


# print footer
printf "\n\n${BOLD}$TOTAL${UNBOLD} Security Groups in region [$REGION]\n\n\n" | indent10

# clean up
rm .ec2-qv-securitygroups.tmp

# <-- end -->

exit 0
