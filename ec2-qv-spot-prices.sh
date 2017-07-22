#!/bin/bash
#
#_________________________________________________________________________
#                                                                         |
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  QuickView of current EC2 spot prices on market               |
#  Name:     ec2-qv-spot-prices.sh                                        |
#  Location: $EC2_REPO                                                    |
#  Requires: awscli, awk, bash, writable dir                              |
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

# Future Enhancements:
#	- InstanceType Array needs auto build via readin of current valid InstanceTypes
#       - Add summary statement displaying region selected, OS, and Instance \
# 	  types for which pricing displayed [single instance pricing only]
#	- Description of InstanceType Chosen to be displayed when only 1 instance type is chosen
#	- Error handling for user data when chosing instance type
#	- After chosing region, display Human Readable region desc instead \
#	  of region code
#

# set vars
NOW=$(date)
E_BADSHELL=7              # exit code if incorrect shell detected
E_BADARG=8                    # exit code if bad input parameter
REGION=$AWS_DEFAULT_REGION    # set region from global env var
#
# Formatting
#
blue=$(tput setaf 4)
cyan=$(tput setaf 6)
green=$(tput setaf 2)
purple=$(tput setaf 5)
red=$(tput setaf 1)
white=$(tput setaf 7)
yellow=$(tput setaf 3)
gray=$(tput setaf 008)
lgray='\033[0;37m'      # light gray
dgray='\033[1;30m'       # dark gray
reset=$(tput sgr0)
#
BOLD=`tput bold`
UNBOLD=`tput sgr0`

# < -- Start -->

echo -e "\n"

# var definition
# REGIONS[] :: List of AWS Global Regions, Array
# REGIONCODE :: Region selected by user
# LOCATION :: Location description of region selected by user
# OS[]	::  Operating System choices, Array
# TYPE :: Operating System selected by user from OS[] array choices
# SIZE[] :: InstanceTypes, Array
# CHOICE :: tmp var holding choice selected by user

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

#
# Validate Shell  ------------------------------------------------------------
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
#  choose region  ------------------------------------------------------------
#

# collect list of all current AWS Regions globally:
aws ec2 describe-regions --output json > .regions.json
ARR_REGIONS=( $(jq -r .Regions[].RegionName .regions.json) )
MAXCT=${#ARR_REGIONS[*]}    # array max length

# output choices
i=0
for region in ${ARR_REGIONS[@]}; do
    # set region location description
    case "${ARR_REGIONS[$i]}" in
        eu-west-1)
            LOCATION="Europe (Ireland)"
            ;;
        eu-west-2)
            LOCATION="Europe (London)"
            ;;
        eu-central-1)
            LOCATION="Europe (Frankfurt, Germany)"
            ;;
        sa-east-1)
            LOCATION="South America (Sao Paulo, Brazil)"
            ;;
        us-east-1)
            LOCATION="United States (N. Virgina)"
            ;;
        us-east-2)
            LOCATION="United States (Ohio)"
            ;;
        us-west-1)
            LOCATION="United States (N. California)"
            ;;
        us-west-2)
            LOCATION="United States (Oregon)"
            ;;
        ap-northeast-1)
            LOCATION="Asia Pacific (Tokyo, Japan)"
	        ;;
		ap-northeast-2)
	        LOCATION="Asia Pacific (Seoul, Korea)"
            ;;
	    ap-south-1)
	        LOCATION="Asia Pacific (Mumbai, India)"
	        ;;
        ap-southeast-1)
            LOCATION="Asia Pacific (Singapore)"
            ;;
        ap-southeast-2)
            LOCATION="Asia Pacific (Sydney, Austrailia)"
            ;;
        ca-central-1)
            LOCATION="Canada (Central)"
            ;;
        *)
            LOCATION="New Region"
            ;;
    esac
    echo "($i): ""${ARR_REGIONS[$i]}"" ""$LOCATION" >> .arrayoutput.tmp
    i=$(( i+1 ))
done

# print header
echo ""
echo -ne ""    "     RegionCode Location\n \
    -------------------- --------------------------------\n" > .header.tmp
# print choices
echo -e "${white}${BOLD}Current AWS Regions Worldwide:${UNBOLD}${reset}\n" | indent02
awk '{ printf "%-23s %-2s %-30s \n", $1, $2, $3}' .header.tmp | indent02
awk '{ printf "%-5s %-17s %-2s %-2s %-2s %-2s %-2s \n", $1, $2, $3, $4, $5, $6, $7}' .arrayoutput.tmp | indent02

# clean up
rm ./.regions.json ./.arrayoutput.tmp ./.header.tmp

# exit if just regions requested (-r switch)
if [ $1 == "-r" ] || [ $1 == "--regions" ]; then
    echo -e "\n"
    exit 0
fi

# enter loop to validate range and type of user entry
VALID=0
while [ $VALID -eq 0 ]; do
	   # read instance choice in from user
	   echo ""
	   read -p "  Select Region [$AWS_DEFAULT_REGION]: " CHOICE
	   echo ""
	   if [ -z "$CHOICE" ]; then
      	  # CHOICE is blank, default region chosen
	        # use the aws_default_region env variable
          REGION=$AWS_DEFAULT_REGION
      	  echo -e "  You Selected: "$REGION"\n"
		      VALID=1   # exit loop
	   else
		     # CHOICE is a value, check type and range
		     #if [[ -n ${CHOICE//[0-$(( $MAXCT-1 ))]/} ]]; then
         if [[ ! "$CHOICE" =~ ^[0-9]+$ ]]; then
             # contains chars
             echo -e "Your entry must be an integer between 0 and $(( $MAXCT-1 )) or hit return."
		     else
             if [[ $CHOICE -ge 0 ]] && [[ $CHOICE -lt $(( $MAXCT )) ]]; then
                 # valid range, reset the aws default region to user choice momentarily
		             REGION=${ARR_REGIONS[$CHOICE]}
	               echo -e "  You Selected: "$REGION"\n"
        	       VALID=1   # exit loop
             else
                 # out of range
                 echo -e "Your entry must be an integer between 0 and $(( $MAXCT-1 )) or hit return."
             fi
	       fi
	   fi
done


#
###  choose Operating System ##############################################
#

OS[0]="Linux/UNIX"
OS[1]="SUSE Linux"
OS[2]="Windows"
MAXCT=${#OS[*]}

# output choices
i=0
while (( i < $MAXCT ))
do
        echo "($i): ""${OS[$i]}"  >> .type.tmp
        i=$(( $i+1 ))
done

# print choices
echo -e "${BOLD}Operating Systems Available:${UNBOLD}\n" | indent02
awk -F "  " '{ printf "%-4s %-20s \n", $1, $2}' .type.tmp | indent02

# get user input while checking type and range
VALID=0    # set loop break

while [ $VALID -eq 0 ]
do
	# read instance choice in from user
	echo ""
	read -p "  Enter OS type [Linux/UNIX]: " CHOICE
	echo ""

	if [[ -n ${CHOICE//[0-$(( $MAXCT-1 ))]/} ]]
	then
		echo "  You must enter an integer number between 0 and $(( $MAXCT-1 ))."
	else
		VALID=1
	fi
done

if [ -z "$CHOICE" ]
then
        # CHOICE is blank, default chosen
	CHOICE=0
fi

# set type
TYPE=${OS[$CHOICE]}
echo -e "  You Selected: "$TYPE"\n"


# clean up
rm ./.type.tmp

#
###  choose Instance size #################################################
#

# build InstanceType array

# general purpose
SIZE[0]='m3.medium'
SIZE[1]='m4.large'
SIZE[2]='m4.xlarge'
SIZE[3]='m4.2xlarge'
SIZE[4]='m4.4xlarge'
# set max count based on # of entries in the previous section
MAXCT=${#SIZE[*]}

# 3rd gen compute optimized
SIZE[5]='c3.large'
SIZE[6]='c3.xlarge'
SIZE[7]='c3.2xlarge'
SIZE[8]='c3.4xlarge'
SIZE[9]='c3.8xlarge'

# mem optimized
SIZE[10]='r3.large'
SIZE[11]='r3.xlarge'
SIZE[12]='r3.2xlarge'
SIZE[13]='r3.4xlarge'
SIZE[14]='r3.8xlarge'

# storage optimized
SIZE[15]='i2.xlarge'
SIZE[16]='i2.2xlarge'
SIZE[17]='i2.4xlarge'
SIZE[18]='i2.8xlarge'
SIZE[19]='hs1.8xlarge'

# 4th gen compute optimized
SIZE[20]='c4.large'
SIZE[21]='c4.xlarge'
SIZE[22]='c4.2xlarge'
SIZE[23]='c4.4xlarge'
SIZE[24]='c4.8xlarge'

set counters
i=0		# general purpose
j=$(( $i+5 ))	# 3rd gen compute optimized
k=$(( $i+10 ))	# mem optimized
l=$(( $i+15 ))	# storage optimized
m=$(( $i+20 ))  # 4th gen compute optimized

# output choices
while (( i < $MAXCT ))
do
        echo "($i): ""${SIZE[$i]}" "($j): ""${SIZE[$j]}" "($k): ""${SIZE[$k]}" "($l): ""${SIZE[$l]}" \
        "($m): ""${SIZE[$m]}" >> data.output
        i=$(( $i+1 ))
        j=$(( $j+1 ))
        k=$(( $k+1 ))
        l=$(( $l+1 ))
	m=$(( $m+1 ))
done

# print output
echo -e "${BOLD}Choose from the following $TYPE EC2 instance types:\n${UNBOLD}" | indent02
echo -e "General Purpose  ""Compute Opt(Gen3)  ""Memory Optimized  ""Storage Optimized  " "Compute Opt(Gen4)" > .header.tmp
echo -e "---------------  ""----------------  ""----------------  ""-----------------   ""-----------------" >> .header.tmp
awk -F "  " '{ printf "%-20s %-20s %-20s %-20s %-20s \n", $1, $2, $3, $4, $5}' .header.tmp | indent02
awk '{ printf "%-4s %-15s %-4s %-15s %-4s %-14s %-4s %-15s %-4s %-15s \n", \
	$1, $2, $3, $4, $5, $6, $7, $8, $9, $10}' data.output | indent02
echo ""

# clean up
rm ./data.output
rm ./.header.tmp

# read instance choice in from user
echo ""
read -p "  Enter Instance size # or hit return for all spot prices [all]: " CHOICE
echo ""

# assign choice

if [ -z "$CHOICE" ]
then
        # CHOICE is blank, default chosen. Show all spot prices
	# for instance types avail in region chosen

	# print title header
	echo -e "\n"
        echo -e "  ${BOLD}Spot pricing for all EC2 instance types${UNBOLD} : $AWS_DEFAULT_REGION:\n"


	# Place Future summary here for:  Region, OS, Instances (all instances)

	# Format prices in ascending order based on RegionCode & OS Type:
	case "$TYPE" in

		# Amazon Linux OS Formatting
		"Linux/UNIX")
        	case "$REGION" in
	                eu-central-1)
        	        # special formatting for long RegionCodes
			#
			# print column header
			echo -e "RegionCode  ""Instance  ""OperSys  ""Price/hr  " > .header.tmp
			echo -e "-------------  ""----------  ""----------  ""--------   " >> .header.tmp
			awk -F " " '{ printf "%-20s %-15s %-15s %-20s \n", $1, $2, $3, $4}' .header.tmp | indent02

                	aws ec2 describe-spot-price-history  \
                          --region $REGION \
                        	--start-time "$NOW" \
	                        --product-description "$TYPE" \
        	                --output text | \
                	        sort -k +5n > .body.tmp     # Cut 1st col, sort by 5th col
			awk -F " " '{printf "%-20s %-20s %-15s %-15s %-10s \n", $1, $2, $3, $4, $5}' .body.tmp | cut -c 22-84 | indent02
	                  ;;

                        ap-*)
			# output formatting ap-northeast-1, ap-southeast-1, or ap-southeast-2
                        #
                        # print column header
                        echo -e "RegionCode  ""Instance  ""OperSys  ""Price/hr  " > .header.tmp
                        echo -e "---------------  ""----------  ""----------  ""--------   " >> .header.tmp
                        awk -F " " '{ printf "%-20s %-15s %-15s %-20s \n", $1, $2, $3, $4}' .header.tmp | indent02

                        aws ec2 describe-spot-price-history  \
                                --region $REGION \
                                --start-time "$NOW" \
                                --product-description "$TYPE" \
                                --output text | \
                                sort -k +5n > .body.tmp      # Cut 1st col, sort by 5th col
                        awk -F " " '{printf "%-20s %-20s %-15s %-15s %-10s \n", $1, $2, $3, $4, $5}' .body.tmp | cut -c 22-84 | indent02
                          ;;

                	*)
	                # all other RegionCodes, use std default formatting
			#
		        # print column header
		        echo -e "RegionCode  ""Instance  ""OperSys  ""Price/hr  " > .header.tmp
		        echo -e "----------  ""----------  ""----------  ""--------   " >> .header.tmp
		        awk -F " " '{ printf "%-15s %-15s %-15s %-20s \n", $1, $2, $3, $4}' .header.tmp | indent02

			aws ec2 describe-spot-price-history  \
                          --region $REGION \
                	        --start-time "$NOW" \
                        	--product-description "$TYPE" \
	                        --output text | \
        	                sort -k +5n > .body.tmp
			awk -F " " '{printf "%-20s %-15s %-15s %-15s %-10s \n", $1, $2, $3, $4, $5}' .body.tmp | cut -c 22-84 | indent02
			;;
		esac
		;;

		# SUSE Linux OS Formatting
		"SUSE Linux")
                case "$REGION" in       # output formatting by RegionCode
                        eu-central-1)
                        # output formatting Frankfurt, Germany
                        #
                        # print column header
                        echo -e "RegionCode  ""Instance  ""OperSys  ""Price/hr  " > .header.tmp
                        echo -e "-------------  ""----------  ""----------  ""--------   " >> .header.tmp
                        awk -F " " '{ printf "%-20s %-15s %-15s %-20s \n", $1, $2, $3, $4}' .header.tmp | indent02

                        aws ec2 describe-spot-price-history  \
                                --region $REGION \
                                --start-time "$NOW" \
                                --product-description "$TYPE" \
                                --output text | \
                                sort -k +6n > .body.tmp      # Cut 1st col, sort by 4th col
                        awk -F " " '{printf "%-20s %-20s %-15s %-3s %-10s %-15s \n", $1, $2, $3, $4, $5, $6}' .body.tmp | cut -c 22-84 | indent02
                          ;;

			ap-*)
			# output formatting ap-northeast-1&2, ap-southeast-1&2
			#
			# print column header
			echo -e "RegionCode  ""Instance  ""OperSys  ""Price/hr  " > .header.tmp
			echo -e "---------------  ""----------  ""----------  ""--------   " >> .header.tmp
			awk -F " " '{ printf "%-20s %-15s %-15s %-20s \n", $1, $2, $3, $4}' .header.tmp | indent02

                        aws ec2 describe-spot-price-history  \
                                --region $REGION \
                                --start-time "$NOW" \
                                --product-description "$TYPE" \
                                --output text | \
                                sort -k +6n > .body.tmp      # Cut 1st col, sort by 4th col
			awk -F " " '{printf "%-20s %-20s %-15s %-3s %-10s %-15s \n", $1, $2, $3, $4, $5, $6}' .body.tmp | cut -c 22-84 | indent02
                          ;;

                        *)
                        # all other RegionCodes, use std default formatting
			#
		        # print column header
		        echo -e "RegionCode  ""Instance  ""OperSys  ""Price/hr  " > .header.tmp
		        echo -e "----------  ""----------  ""----------  ""--------   " >> .header.tmp
		        awk -F " " '{ printf "%-15s %-15s %-15s %-20s \n", $1, $2, $3, $4}' .header.tmp | indent02

                        aws ec2 describe-spot-price-history  \
                                --region $REGION \
                                --start-time "$NOW" \
                                --product-description "$TYPE" \
                                --output text | \
                                sort -k +6n > .body.tmp
			awk -F " " '{printf "%-20s %-15s %-15s %-3s %-10s %-15s \n", $1, $2, $3, $4, $5, $6}' .body.tmp | cut -c 22-84 | indent02
                        ;;
                esac
		;;

		# Windows OS Formatting
		"Windows")

                case "$REGION" in
                        eu-central-1)
                        # print column header
                        echo -e "RegionCode  ""Instance  ""OperSys  ""Price/hr  " > .header.tmp
                        echo -e "-------------  ""----------  ""-------  ""--------   " >> .header.tmp
                        awk -F " " '{ printf "%-20s %-15s %-13s %-20s \n", $1, $2, $3, $4}' .header.tmp | indent02

                        # special formatting for long RegionCodes
                        aws ec2 describe-spot-price-history  \
                                --region $REGION \
                                --start-time "$NOW" \
                                --product-description "$TYPE" \
                                --output text | \
                                sort -k +5n > .body.tmp     # Cut 1st col, sort by 4th col
	               awk -F " " '{printf "%-20s %-20s %-15s %-13s %-15s \n", $1, $2, $3, $4, $5}' .body.tmp | cut -c 22-84 | indent02
                          ;;

                        ap-northeast-1 | ap-northeast-2)
	                # print column header
        	        echo -e "RegionCode  ""Instance  ""OperSys  ""Price/hr  " > .header.tmp
                	echo -e "---------------  ""----------  ""-------  ""--------   " >> .header.tmp
	                awk -F " " '{ printf "%-20s %-15s %-13s %-20s \n", $1, $2, $3, $4}' .header.tmp | indent02

			# special formatting for long RegionCodes
                        aws ec2 describe-spot-price-history  \
                                --region $REGION \
                                --start-time "$NOW" \
                                --product-description "$TYPE" \
                                --output text | \
                                sort -k +5n > .body.tmp     # Cut 1st col, sort by 4th col
	               awk -F " " '{printf "%-20s %-20s %-15s %-13s %-15s \n", $1, $2, $3, $4, $5}' .body.tmp | cut -c 22-84 | indent02

                          ;;

                        ap-southeast-1)
                        # print column header
                        echo -e "RegionCode  ""Instance  ""OperSys  ""Price/hr  " > .header.tmp
                        echo -e "---------------  ""----------  ""-------  ""--------   " >> .header.tmp
                        awk -F " " '{ printf "%-20s %-15s %-13s %-20s \n", $1, $2, $3, $4}' .header.tmp | indent02

                        # special formatting for long RegionCodes
                        aws ec2 describe-spot-price-history  \
                                --region $REGION \
                                --start-time "$NOW" \
                                --product-description "$TYPE" \
                                --output text | \
                                sort -k +5n > .body.tmp     # Cut 1st col, sort by 4th col
	               awk -F " " '{printf "%-20s %-20s %-15s %-13s %-15s \n", $1, $2, $3, $4, $5}' .body.tmp | cut -c 22-84 | indent02

                          ;;

                        ap-southeast-2)

                        # print column header
                        echo -e "RegionCode  ""Instance  ""OperSys  ""Price/hr  " > .header.tmp
                        echo -e "---------------  ""----------  ""-------  ""--------   " >> .header.tmp
                        awk -F " " '{ printf "%-20s %-15s %-13s %-20s \n", $1, $2, $3, $4}' .header.tmp | indent02

                        # special formatting for long RegionCodes
                        aws ec2 describe-spot-price-history  \
                                --region $REGION \
                                --start-time "$NOW" \
                                --product-description "$TYPE" \
                                --output text | \
                                sort -k +5n > .body.tmp     # Cut 1st col, sort by 4th col
	               awk -F " " '{printf "%-20s %-20s %-15s %-13s %-15s \n", $1, $2, $3, $4, $5}' .body.tmp | cut -c 22-84 | indent02

                          ;;

                        *)
                        # ALL OTHER RegionCodes, use std default formatting
 			#
                        # print column header
                        echo -e "RegionCode  ""Instance  ""OperSys  ""Price/hr  " > .header.tmp
                        echo -e "----------  ""----------  ""-------  ""--------   " >> .header.tmp
                        awk -F " " '{ printf "%-15s %-15s %-13s %-20s \n", $1, $2, $3, $4}' .header.tmp | indent02
                        aws ec2 describe-spot-price-history  \
                                --region $REGION \
                                --start-time "$NOW" \
                                --product-description "$TYPE" \
                                --output text | \
                                sort -k +5n > .body.tmp     # Cut 1st col, sort by 4th col
	               	awk -F " " '{printf "%-15s %-15s %-15s %-13s %-15s \n", $1, $2, $3, $4, $5}' .body.tmp | cut -c 18-80 | indent02
                          ;;
		esac
		  ;;

	esac

        # clean up, display all section complete
        rm ./.header.tmp
	rm ./.body.tmp

else
	# display current spot prices only for specific instance type in region chosen
	aws ec2 describe-spot-price-history  \
    --region $REGION \
		--start-time "$NOW" \
		--product-description "$TYPE" \
		--instance- ${SIZE[$CHOICE]} \
		--output table
fi

# <-- end -->

# line feed
echo -e "\n"

exit 0
