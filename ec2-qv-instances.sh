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
# set vars
#

BOLD=`tput bold`
UNBOLD=`tput sgr0`		
E_BADSHELL=7                  # exit code if incorrect shell detected
E_BADARG=8                    # exit code if bad input parameter		
REGION=$AWS_DEFAULT_REGION    # set region from global env var

# set fs pointer to writeable temp location
if [ "$(df /run | awk '{print $1, $6}' | grep tmpfs 2>/dev/null)" ]
then
	# in-memory
        TMPDIR="/dev/shm"
        cd $TMPDIR     
else
        TMPDIR="/tmp"
        cd $TMPDIR 
fi

#
# functions  ------------------------------------------------------------------
#

# formatting
indent02() { sed 's/^/  /'; }
indent10() { sed 's/^/          /'; }
indent18() { sed 's/^/                  /'; }

# time format refactor
function convert_time () {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo "$day"d,"$hour"h,"$min"m  
}

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
		echo -e "  [region code] :  Instances details for specified alternate region"
		echo -e "  [no arg]      :  Instance details for region specified by AWS_DEFAUT_REGION env variable\n"
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
printf "\n\n${BOLD}EC2 Instances${UNBOLD} : $REGION\n\n\n" | indent18

# pull json info, all instances
aws ec2 describe-instances --region $REGION > .jsonoutput.tmp

#
# load fields into respective arrays
#
ARR_STATE=( $(jq -r '.Reservations[].Instances[].State.Name' .jsonoutput.tmp) )
ARR_IP=( $(jq -r '.Reservations[].Instances[].PublicIpAddress' .jsonoutput.tmp) )
ARR_LT=( $(jq -r '.Reservations[].Instances[].LaunchTime' .jsonoutput.tmp) )
ARR_ID=( $(jq -r '.Reservations[].Instances[].InstanceId' .jsonoutput.tmp) )
ARR_TYPE=( $(jq -r '.Reservations[].Instances[].InstanceType' .jsonoutput.tmp) )
ARR_DEV=( $(jq -r '.Reservations[].Instances[].BlockDeviceMappings[0].Ebs.VolumeId' .jsonoutput.tmp) )

# limit security grp name to 15 chars
ARR_SG=( $(jq -r '.Reservations[].Instances[].SecurityGroups[0].GroupName' .jsonoutput.tmp | cut -c 1-15) )

# limit length of tag fields to 20 chars
ARR_TAG=( $(jq -r '.Reservations[].Instances[].Tags[0].Value' .jsonoutput.tmp | cut -c 1-20) )

# count instances found
MAXCT=${#ARR_STATE[*]} 

#
# test, running instances
#
if [ "$(printf '%s\n' "${ARR_STATE[@]}" | grep "running")" ]
then
	#
	# at least 1 running instance found, calc runtime
 	#
 	i=0    	# counter
 	r=0	# running instance count
 	while (( i < $MAXCT ))
 	do
 		if [ "${ARR_STATE[$i]}" == "running" ]
 		then
			# calc now in UTC epoch seconds
			NOW=$(date -u +%s)

			# calc launchtime
			LAUNCHTIME="${ARR_LT[$i]}"
			EPOCHLT=$(date -d"$LAUNCHTIME" +%s)
			RUNSECS=$(( $NOW-$EPOCHLT ))	# runtime (seconds)
			RT[$i]=$(convert_time $RUNSECS)

			# track # running instances
			r=$(( $r+1 ))

		else
			# if not running, blank runtime
			RT[$i]="-"
		fi

		# convert public IP format
		if [ "${ARR_IP[$i]}" == "null" ]
		then
			# alter IP format
			ARR_IP[$i]="None"
		fi

		# incr ct
		i=$(( $i+1 ))

	done


	# print header
	echo -ne "InstanceId Type State SecurityGroup Root-Volume Public-IP RunTime Tag\n \
        ----------  ---------  ---------- --------------    ------------   \
        --------------  -----------   --------------------\n" > .body.tmp
	
	#
	# output table of json array
	#
	i=0
	while (( i < $MAXCT ))
	do
		echo "${ARR_ID[$i]}  ${ARR_TYPE[$i]}  ${ARR_STATE[$i]} ${ARR_SG[$i]}  \
			  ${ARR_DEV[$i]}  ${ARR_IP[$i]}  ${RT[$i]}  ${ARR_TAG[$i]}" >> .body.tmp
		i=$(( $i+1 ))
	done


	# print and format output
	#
	# values
	awk  '{ printf "%-11s %-10s %-11s %-15s %-13s %-15s %-12s %-2s %-2s \n", \
    	    $1, $2, $3, $4, $5, $6, $7, $8, $9}' .body.tmp | indent02

    	# print footer
    	printf "\n\nTotal Instances [$REGION]: ${BOLD}$MAXCT${UNBOLD}    ($r currently running)\n\n" | indent10

else
	# no running instances, eliminate PublicIP and RunTime columns, print header
        echo -ne "InstanceId* Type State SecurityGroup Root-Volume Tag\n \
        ---------- --------- ---------- -------------- ------------ \
        --------------------\n" > .body.tmp

	#
	# output table of json array
	#
	i=0
	while (( i < $MAXCT ))
	do
		echo "${ARR_ID[$i]} ${ARR_TYPE[$i]} ${ARR_STATE[$i]} ${ARR_SG[$i]} \
			  ${ARR_DEV[$i]} ${ARR_TAG[$i]}" >> .body.tmp

		# incr ct	  
		i=$(( $i+1 ))
	
	done

    	# print and format output
    	#
    	# Note: Since awk is looking for blank space as delimiter, we allow spaces
    	#
    	awk  '{ printf "%-11s %-10s %-11s %-16s %-13s %-10s %-2s %-2s %-2s %-2s \n", \
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10}' .body.tmp | indent02

	# print footer
	printf "\n\nTotal Instances [$REGION]: ${BOLD}$MAXCT${UNBOLD}    *No running instances.\n\n" | indent10

fi

# clean up
rm .body.tmp .jsonoutput.tmp

# <-- End -->

exit 0
