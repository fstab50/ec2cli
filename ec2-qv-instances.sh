#!/bin/bash
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  QuickView of ec2 instances in the AWS acct                   |  
#            indicated by $AWS_ACCESS_KEY                                 |
#  Name:     ec2-qv-instances.sh                                          |
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
#  Log:  N/A                                                              |
#                                                                         |
#_________________________________________________________________________|

#
#  FUTURE
#	- Ability to pick from list and start, stop, or terminate
#	
# < -- Start -->
#

# set vars
BOLD=`tput bold`
UNBOLD=`tput sgr0`
E_BADSHELL=7            # exit code if incorrect shell detected

# functions
indent18() { sed 's/^/                  /'; }

# print region identifier
printf "\n\n${BOLD}EC2 INSTANCES:${UNBOLD} $AWS_DEFAULT_REGION\n\n" | indent18

# test default shell, fail if debian default (dash)
case "$SHELL" in
  *dash*)
        # shell is ubuntu default, dash
        echo "\nDefault shell appears to be dash. Please rerun with bash. Exiting. Code $E_BADSHELL\n"
        exit $E_BADSHELL
  ;;
esac

# retrieve ext dns names
aws ec2 describe-instances \
        --output text \
        --query 'Reservations[*].Instances[*].[PublicDnsName]' \
> .ec2-publicnames.tmp

# test for public dns name assignment
if [ ! -z "$(grep amazonaws.com .ec2-publicnames.tmp)" ]
then
	# public dns name assigment found, print header
	echo -ne "InstanceId Type State SecurityGroup Root-Volume Description PublicDnsName\n \
	---------- --------- ------- -------------- ------------ --------------------- \
	--------------------------------------------------\n" > .ec2-qv-instances.tmp

	# output from aws
	aws ec2 describe-instances \
	        --output text \
        	--query "Reservations[*].Instances[*]. \
			[InstanceId, \
                	InstanceType, \
                	State.Name, \
                	SecurityGroups[0].GroupName, \
                	BlockDeviceMappings[0].Ebs.VolumeId, \
                	Tags[1].Value, \
                	PublicDnsName]" \
	>> .ec2-qv-instances.tmp

	# print and format output
	#
	# Note: Since awk is looking for blank space as delimiter, we allow spaces
	#
	awk  '{ printf "%-11s %-10s %-8s %-16s %-13s %-22s %-50s \n", \
		$1, $2, $3, $4, $5, $6, $7}' .ec2-qv-instances.tmp
else
	# public dns name not found, eliminate PublicDnsName column, print header
        echo -ne "InstanceId Type State SecurityGroup Root-Volume Description\n \
        ---------- --------- ------- -------------- ------------ ---------------------\n" \
	> .ec2-qv-instances.tmp

	# output from aws
	aws ec2 describe-instances \
        	--output text \
        	--query "Reservations[*].Instances[*]. \
			[InstanceId, \
			InstanceType, \
			State.Name, \
			SecurityGroups[0].GroupName, \
			BlockDeviceMappings[0].Ebs.VolumeId, \
			Tags[1].Value]" \
		>> .ec2-qv-instances.tmp

        # print and format output
        #
        # Note: Since awk is looking for blank space as delimiter, we allow spaces
        #
        awk  '{ printf "%-11s %-10s %-8s %-16s %-13s %-10s %-2s %-2s %-2s %-2s \n", \
		$1, $2, $3, $4, $5, $6, $7, $8, $9, $10}' .ec2-qv-instances.tmp
fi

# print footer
echo " "

# clean up
rm .ec2-qv-instances.tmp .ec2-publicnames.tmp

# <-- End -->

exit 0
