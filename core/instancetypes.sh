#!/bin/bash

#####################################################
### get EC2 Instance Type Inventory - all Regions ###
#####################################################
#                                                   #
# Author:  Blake Huber                              #
#                                                   #
#####################################################

# global vars
E_DEPENDENCY=1			# exit code if missing deps
NOW=$(date +"%Y-%m-%d")
path=$(cd $(dirname $0); pwd -P)
PRICEFILE="ec2inventory_allregions.json"
OFFERFILE="ec2offerfile_allregions.json"
INDEXURL="https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json"
ONEDAY=$(( 24*60*60 ))    # 24 hours in seconds

# formatting
source ./lib/colors.sh
nc=$(tput sgr0)           # no color


#<-- function declaration start -->

function dependency_check(){
    ## check for required cli tools ##
    for prog in stat date printf wget sort sed; do
        if ! type "$prog" > /dev/null 2>&1; then
            echo "[ERROR]: $prog is required and not found in the PATH. Aborting (code $E_DEPENDENCY)"
            exit $E_DEPENDENCY
        fi
    done
    ## create dir and file for recording historical ec2 instance types ##
	if [[ ! -d $path/types ]]; then
    	if ! mkdir -p "$path/types"; then
        	echo "[ERROR] $pkg: failed to make EC2 instance types directory: $path/types"
	        exit $E_DEPENDENCY
    	fi
	fi
}

function get_ec2_pricefile(){
	echo -e "\n[INFO]: Downloading a current EC2 inventory price file from AWS.\n"
	# retrieve current url of EC2 price files
	wget $INDEXURL
	CurrentURL="https://pricing.us-east-1.amazonaws.com"$(jq -r '.offers.AmazonEC2.currentVersionUrl' index.json)
	#echo -e "\nCurrent EC2 Price API url found: "$CurrentURL"\n"
	rm index.json
	# pull on-demand pricing from current EC2 Price API url
	wget $CurrentURL
	mv -v index.json $PRICEFILE 1>&2
}

function get_ec2_offerfile(){
	echo -e "[INFO]: Retrieving offerfile to validate last official release date...\n"
	wget $INDEXURL
	mv index.json $OFFERFILE 1>&2
}


# <-- main start -->

# validate deps
dependency_check

###
### retreive current ec2 inventory price file from AWS
###

if [[ ! -e $PRICEFILE ]]; then
    echo -e "\n[INFO]: EC2 local price file not found, retrieving new file..."
    get_ec2_pricefile $PRICEFILE
else
	echo -e "\n[INFO]: Local file [$PRICEFILE] has been found, released $(stat -c '%.10y' $PRICEFILE)"
    get_ec2_offerfile $OFFERFILE
    # grab publicationDate and convert to epoch seconds
    PUBDATE=$(date -d$(jq -r .publicationDate $OFFERFILE) +%s)
    echo "[INFO]: Last AWS official release date found was: "$(date --date=@$PUBDATE)
    LOCALDATE=$(stat -c '%Y' $PRICEFILE)
    if [[ $(( $PUBDATE - $LOCALDATE )) -gt $ONEDAY ]]; then
    	# aws has released an update
    	echo "AWS official EC2 inventory recently updated.  Downloading new inventory file..."
    	get_ec2_pricefile $PRICEFILE
    else
    	echo "[INFO]: Local file matches latest AWS Official release date within 24 hours."
        echo "[INFO]: Processing local EC2 inventory file."
    fi
    # clean up
    rm $OFFERFILE 1>&2
fi

###
### process inventory file
###

ARR_TYPES=( $(jq -r '.products | map(.attributes.instanceType)' $PRICEFILE) )
# initial array scrub - remove duplicates, quotes
ARR_CLEAN=( $(printf '%s\n' "${ARR_TYPES[@]}" | sort -u | sed -e 's|["'\'']||g') )
# create array of all additional elements to remove
ARR_REMOVE=( ${ARR_CLEAN[@]/*.*/} "," )
# remove ARR_REMOVE elements from ARR_CLEAN
for i in "${ARR_REMOVE[@]}"; do
	ARR_CLEAN=( ${ARR_CLEAN[@]//"$i"} )
done
TYPE_CT=${#ARR_CLEAN[@]}    # total number of instance types available

###
### output cleaned list of ec2 instance types
###

INV_REFRESH_DATE="$(stat -c '%.10y' $PRICEFILE)"    # AWS source file refresh date
INV_FILE=$INV_REFRESH_DATE"_ec2types_inventory.log"
i=0
if [[ ! -e $path/types/$INV_FILE ]]; then
	for type in ${ARR_CLEAN[@]}; do
		echo ${ARR_CLEAN[$i]} >> $path/types/$INV_FILE
		i=$(( i+1 ))
	done
fi

###
### create new arrays for each instance family type (m, t, d, etc)
###

# create array for each respective instance type
for type in ${ARR_CLEAN[@]}; do
	case $type in
		c1* | c2* | c3*)
			ARR_C=( ${ARR_C[@]} "$type" )
			;;
		c4*)
			ARR_C4=( ${ARR_C4[@]} "$type" )
			;;
        c5*)
			ARR_C5=( ${ARR_C5[@]} "$type" )
			;;
		d*)
			ARR_D=( ${ARR_D[@]} "$type" )
			;;
		g*)
			ARR_G=( ${ARR_G[@]} "$type" )
			;;
		h*)
			ARR_H=( ${ARR_H[@]} "$type" )
			;;
        f1*)
			ARR_F1=( ${ARR_F1[@]} "$type" )
			;;
		i*)
			ARR_I=( ${ARR_I[@]} "$type" )
			;;
		m1* | m2* | m3*)
			ARR_M=( ${ARR_M[@]} "$type" )
			;;
        m4*)
			ARR_M4=( ${ARR_M4[@]} "$type" )
			;;
        m5*)
			ARR_M5=( ${ARR_M5[@]} "$type" )
			;;
		p*)
			ARR_P=( ${ARR_P[@]} "$type" )
			;;
		r*)
			ARR_R=( ${ARR_R[@]} "$type" )
			;;
		t*)
			ARR_T=( ${ARR_T[@]} "$type" )
			;;
		x*)
			ARR_X=( ${ARR_X[@]} "$type" )
			;;
		*)
			ARR_MISC=( ${ARR_MISC[@]} "$type" )
			;;
	esac
done

T_CT=${#ARR_T[@]}

M_CT=${#ARR_M[@]}
M4_CT=${#ARR_M4[@]}
M5_CT=${#ARR_M5[@]}
TOTAL_M=$(( $M_CT + $M4_CT + $M5_CT ))

C_CT=${#ARR_C[@]}
C4_CT=${#ARR_C4[@]}
C5_CT=${#ARR_C5[@]}
TOTAL_C=$(( $C_CT + $C4_CT + $C5_CT ))

D_CT=${#ARR_D[@]}
H_CT=${#ARR_H[@]}
I_CT=${#ARR_I[@]}
TOTAL_DHI=$(( $D_CT + $H_CT + $I_CT ))
###
### output ec2 families
###

printf '%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
echo -e "${BOLD}EC2 Instance Types Summary ${UNBOLD}\n" | indent04
echo -e " * Date of last EC2 instance type refresh by AWS was [$INV_REFRESH_DATE]."
echo -e " * $INV_FILE stored in $path/types/"
echo -e " * Instance types identified: ${BOLD}${white}$TYPE_CT${nc}"
printf '%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _


echo -e "\n${BOLD}EC2 Instance Families Identified ${UNBOLD}" | indent04
echo -e "____________________________________\n" | indent02

echo -e "\n${accent}General Purpose Burstable (T type):${nc} $T_CT Types"
echo ${ARR_T[@]} | sort

echo -e "\n${BOLD}${white}General Purpose (M type)${nc}: $TOTAL_M Types"
echo -e "\n${accent}Gen 1-3 (M1, M2, or M3 types):${nc}" | indent04
echo -e ${ARR_M[@]} | indent04
echo -e "\n${accent}Gen 4 (M4 type):${nc}" | indent04
echo -e ${ARR_M4[@]} | indent04
echo -e "\n${accent}Gen 5 (M5 type):${nc}" | indent04
echo -e ${ARR_M5[@]} | indent04

echo -e "\n${BOLD}${white}Compute Optimized (C type)${nc}: $TOTAL_C Types"
echo -e "\n${accent}Gen 1-3 (C1, C2, or C3 type):${nc}" | indent04
echo -e ${ARR_C[@]} | indent04
echo -e "\n${accent}Gen 4 (C4 type):${nc}" | indent04
echo ${ARR_C4[@]} | indent04
echo -e "\n${accent}Gen 5 (C5 type):${nc}" | indent04
echo ${ARR_C5[@]} | indent04

echo -e "\n${BOLD}${white}Storage Optimized${nc}: $TOTAL_DHI${nc} Types"
echo -e "\n${accent}Dense-storage (D type):${nc}"  | indent04
echo ${ARR_D[@]} | indent04
echo -e "\n${accent}Hi-Throughput Gen 3 (H type):${nc}" | indent04
echo ${ARR_H[@]} | indent04
echo -e ${accent}"\nHigh I/O (I type):"${nc} | indent04
echo ${ARR_I[@]} | sort | indent04

G_CT=${#ARR_G[@]}
echo -e "\n${accent}GPU Graphics Optimized (G type):${nc} $G_CT Types"
echo ${ARR_G[@]} | sort

P_CT=${#ARR_P[@]}
echo -e "\n${accent}GPU General Purpose (P type):${nc} $P_CT Types"
echo ${ARR_P[@]} | sort

R_CT=${#ARR_R[@]}
echo -e "\n${accent}Memory Optimized (R type):${nc} $R_CT Types"
echo ${ARR_R[@]} | sort

X_CT=${#ARR_X[@]}
echo -e "\n${accent}Memory Optimized (X type):${nc} $X_CT Types"
echo ${ARR_X[@]} | sort

F1_CT=${#ARR_F1[@]}
echo -e "\n${accent}FPGA Gen 1 (F type):${nc} $F1_CT Types"
echo ${ARR_F1[@]} | sort

MISC_CT=${#ARR_MISC[@]}
echo -e "\n${accent}Miscellaneous EC2 instances:${nc} $MISC_CT Types"
echo ${ARR_MISC[@]} | sort
echo -e "\n"


# clean up
#rm "$path/ec2inventory_allregions.json"

# <-- end -->
exit 0
