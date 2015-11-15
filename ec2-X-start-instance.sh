#!/bin/bash
#
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  Utility for taking snapshots of EBS volumes                  |
#  Name:     ec2-X-take-snapshot.sh                                       |
#  Location: $EC2_REPO                                                    |
#  Requires: awscli, jq (JSON parser)                                     |
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

# Future Enhancements:
#	- Change default choice to abort (don't start any instances)
#	- Update choice display to put numbered choices in front of rows
#       - Modify spinner() to include display of snap progress % with each iteration of internal while loop
#       - Test for Linux EC2 instance start (this script ONLY good for Linux
#	  since ssh login at end 
#       - Error handling for all user entered data
#     

# < -- Start -->

echo -e "\n"

# vars
NOW=$(date)
PROGRESSTXT="EC2 Instance Starting Up.  Please wait... "
BOLD=`tput bold`
UNBOLD=`tput sgr0`
SGROUP1="security-grp01"		# security group to be verified
SGROUP2="security-grpXRX"
E_BADSHELL=7 			# exit code if incorrect shell
E_NETWORK_ACCSS=8       	# exit code if no network access from current location

# spinner progress marker function
spinner()
{
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r$PROGRESSTXT[%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    #printf "    \b\b\b\b"
}

#
# validate shell env ----------------------------------------------------------
#

# test default shell, fail if debian default (dash)
case "$SHELL" in
  *dash*)
        # shell is ubuntu default, dash
        echo "\nDefault shell appears to be dash. Please rerun with bash. Exiting. Code $E_BADSHELL\n"
        exit $E_BADSHELL
  ;;
esac

#
# network access check -------------------------------------------------
#

echo -e "\nChecking Network Access.  Please wait ..."

# grab myip
dig +short myip.opendns.com @resolver1.opendns.com > .myip.tmp
MYIP=$(cat .myip.tmp)

# query ip's from assigned security group
aws ec2 describe-security-groups \
        --group-names $SGROUP1 $SGROUP2 \
        --output text \
        --query 'SecurityGroups[].[IpPermissions[].IpRanges[*].CidrIp]' > .output.tmp

if grep "$MYIP" .output.tmp > /dev/null
then
        echo -e "\nNetwork access ok, proceeding.\n"
        rm .myip.tmp .output.tmp   # clean up
else
        echo -e "\nNo Network access from this location.  Please update security group.\n"
        rm .myip.tmp .output.tmp   # clean up
        exit $E_NETWORK_ACCESS
fi

#
# choose instance ----------------------------------------------------------
#

# display volumes associated with default zone for user's AWS account
sh $EC2_REPO/ec2-qv-instances.sh    # includes header

echo -e "\nEnter the # of the instance you wish to start:"

# collect list of all current AWS Regions globally:
aws ec2 describe-instances \
        --output text \
        --query 'Reservations[*].[Instances[*].InstanceId]' \
>> .text-output.tmp

# Use built-in IFS to read in all lines in tmp file
IFS=$'\n' read -d '' -r -a INSTANCES < .text-output.tmp

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
cat .arrayoutput.tmp

# read choice in from user
echo ""
read -p "Enter # of choice or hit return for default [0]: " CHOICE
echo ""

# assign volume to choice

if [ -z "$CHOICE" ]
then
        # CHOICE is blank, assign default
        CHOICE=0
fi

TARGET=${INSTANCES[$CHOICE]}
echo "You chose to start instance $TARGET."

# clean up
rm .text-output.tmp
rm .arrayoutput.tmp

#
# start instance ---------------------------------------------------------
#

# start remote instance
aws ec2 start-instances --instance-ids $TARGET | jq . 

# wait for instance to start, return after
aws ec2 wait instance-running --instance-ids $TARGET &

# call function to show on screen while wait
spinner


# get public hostname assignment
HOSTNAME=$(aws ec2 describe-instances \
        --output text \
        --instance-id $TARGET \
        --query 'Reservations[*].Instances[*].[PublicDnsName]') 

# login
ssh -i ~/AWS/awskey_us-west-2.pem ec2-user@$HOSTNAME

#
#<-- end --->

exit 0

