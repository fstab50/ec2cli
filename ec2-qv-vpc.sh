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
E_BADSHELL=7		#  exit code if incorrect shell
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
        echo "\n  Default shell appears to be something other than bash. \
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
    		echo -e "  [region code] :  VPC details for specified alternate region"
    		echo -e "  [no arg]      :  VPC details for region specified by AWS_DEFAULT_REGION env variable\n"
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
printf "\n\n${BOLD}Virtual Private Clouds (VPC)${UNBOLD} : $REGION\n\n" | indent18

# print header 
echo -ne "\nVpcId State Tenancy CIDR-Block Default\n \
        ------------ --------- ------- ------------------ -------\n" > .ec2-qv-vpc.tmp

#
# output from aws
#
aws ec2 describe-vpcs \
	--output text \
  --region $REGION \
	--query "Vpcs[*]. \
		[VpcId, \
		State, \
		InstanceTenancy, \
		CidrBlock, \
		IsDefault]" | sort -k +4n \
>> .ec2-qv-vpc.tmp 

# count total
TOTAL=$(cat .ec2-qv-vpc.tmp | grep "vpc-" | wc -l)

# print and format output
#
# Note: Since awk is looking for blank space as delimiter, we allow spaces
#       in the description field by telling awk these are 2 char columns.
#
awk  '{ printf "%-14s %-10s %-9s %-20s %-9s \n", \
        $1, $2, $3, $4, $5}' .ec2-qv-vpc.tmp | indent02

# print footer
printf "\n\nTotal VPCs, $REGION: ${BOLD}$TOTAL${UNBOLD}\n\n\n" | indent18

# clean up
rm .ec2-qv-vpc.tmp

# <-- end -->

exit 0
