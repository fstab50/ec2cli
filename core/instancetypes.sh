#!/bin/bash

#####################################################
### get EC2 Instance Type Inventory - all Regions ###
#####################################################
#                                                   #
# Author:  Blake Huber                              #
#                                                   #
#####################################################

# global vars
DISPLAY_INSTANCE_TYPES="$1"                 # create ec2 types file + diplay instance types report
RETAIN_DOWNLOADS="true"
E_DEPENDENCY=1			# exit code if missing deps
NOW=$(date +"%Y-%m-%d")
pkg_path=$(cd $(dirname $0); pwd -P)
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
ec2cli_log=$ROOT"/logs/ec2cli.log"

# Configuration files, ancillary vars
CONFIG_DIR="ec2cli"
CONFIG_ROOT="$HOME/.config"
CONFIG_PATH="$CONFIG_ROOT/$CONFIG_DIR"
CONFIG_PATH_ALT="$HOME/.ec2cli"

# price globals
PRICEFILE="ec2prices_allregions.json"
OFFERFILE="ec2offerfile_allregions.json"
INDEXURL="https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json"
ONEDAY=$(( 24*60*60 ))    # 24 hours in seconds

# source config file location
config_dir=$(cat $pkg_path/pkgconfig.json | jq -r .config_dir)

# source colors library
source $pkg_path/colors.sh

# source standard functions
source $pkg_path/std_functions.sh
nc=$(tput sgr0)           # no color


#<-- function declaration start -->

function dependency_check(){
    ## check for required cli tools ##
    for prog in stat date printf wget sort sed; do
        if ! type "$prog" > /dev/null 2>&1; then
            std_message "$prog is required and not found in the PATH. Aborting (code $E_DEPENDENCY)" "WARN" $ec2cli_log
            exit $E_DEPENDENCY
        fi
    done
    ## create dir and file for recording historical ec2 instance types ##
	if [ ! -d $CONFIG_PATH ]; then
	    if [ ! -d $CONFIG_PATH_ALT ]; then
            std_message "[ERROR] $pkg: failed to find ec2cli configuration directory: $CONFIG_PATH" "WARN" $ec2cli_log
	        exit $E_DEPENDENCY
        else
            CONFIG_PATH=$CONFIG_PATH_ALT
    	fi
	fi
}

function get_ec2_pricefile(){
	std_message "Downloading a current EC2 inventory price file from AWS." "INFO" $ec2cli_log
	# retrieve current url of EC2 price files
	wget $INDEXURL
	CurrentURL="https://pricing.us-east-1.amazonaws.com"$(jq -r '.offers.AmazonEC2.currentVersionUrl' index.json)

	rm index.json
	# pull on-demand pricing from current EC2 Price API url
	wget $CurrentURL
	mv -v index.json $PRICEFILE 1>&2
}

function get_ec2_offerfile(){
    if [ ! -e $OFFERFILE ]; then
	    std_message "Retrieving offerfile to validate last official release date..." "INFO" $ec2cli_log
	    wget $INDEXURL
	    mv index.json $OFFERFILE 1>&2
    else
        std_message "$OFFERFILE found, skipping download new." "INFO" $ec2cli_log
        return
    fi
}

function clean_up(){
    if [ ! "$RETAIN_DOWNLOADS" ] || [ "$RETAIN_DOWNLOADS" = "false" ]; then
        # offer location file
        rm $OFFERFILE || true
        # ec2 price file
        rm "$pkg_path/$PRICEFILE" || true
    fi
}

# <-- main start -->

# validate deps
dependency_check

###
### retreive current ec2 inventory price file from AWS
###

if [ ! -f $PRICEFILE ]; then
    std_message "EC2 local price file not found, retrieving new file..." "INFO" $ec2cli_log
    get_ec2_pricefile $PRICEFILE
else
	std_message "Local file [$PRICEFILE] has been found, released $(stat -c '%.10y' $PRICEFILE)" "INFO" $ec2cli_log
    get_ec2_offerfile $OFFERFILE
    # grab publicationDate and convert to epoch seconds
    PUBDATE=$(date -d$(jq -r .publicationDate $OFFERFILE) +%s)
    std_message "Last AWS official release date found was: "$(date --date=@$PUBDATE) "INFO" $ec2cli_log
    LOCALDATE=$(stat -c '%Y' $PRICEFILE)
    if [[ $(( $PUBDATE - $LOCALDATE )) -gt $ONEDAY ]]; then
    	# aws has released an update
    	std_message "AWS official EC2 inventory recently updated.  Downloading new inventory file..." "INFO" $ec2cli_log
    	get_ec2_pricefile $PRICEFILE
    else
    	std_message "Local file matches latest AWS Official release date within 24 hours." "INFO" $ec2cli_log
        std_message "Processing local EC2 inventory file." "INFO" $ec2cli_log
    fi
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
INV_FILE="types.ec2"

if [ ! -e "$CONFIG_PATH/$INV_FILE" ]; then
	for type in ${ARR_CLEAN[@]}; do
		echo $type >> "$CONFIG_PATH/$INV_FILE"
	done
fi

if [ ! "$DISPLAY_INSTANCE_TYPES" = "true" ]; then
    # only create instance types file, then stop
    clean_up
    exit 0
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
echo -e "${title}EC2 Instance Types Summary ${bodytext}\n" | indent04
echo -e " * Date of last EC2 instance type refresh by AWS was [$INV_REFRESH_DATE]."
echo -e " * $INV_FILE stored in $pkg_path/types/"
echo -e " * Instance types identified: ${title}${white}$TYPE_CT${nc}"
printf '%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _


echo -e "\n${title}EC2 Instance Families Identified ${bodytext}" | indent04
echo -e "____________________________________\n" | indent02

echo -e "\n${title}General Purpose Burstable (T type):${nc} $T_CT Types"
echo ${ARR_T[@]} | sort

echo -e "\n${title}${white}General Purpose (M type)${nc}: $TOTAL_M Types"
echo -e "\n${title}Gen 1-3 (M1, M2, or M3 types):${nc}" | indent04
echo -e ${ARR_M[@]} | indent04
echo -e "\n${title}Gen 4 (M4 type):${nc}" | indent04
echo -e ${ARR_M4[@]} | indent04
echo -e "\n${title}Gen 5 (M5 type):${nc}" | indent04
echo -e ${ARR_M5[@]} | indent04

echo -e "\n${title}${white}Compute Optimized (C type)${nc}: $TOTAL_C Types"
echo -e "\n${title}Gen 1-3 (C1, C2, or C3 type):${nc}" | indent04
echo -e ${ARR_C[@]} | indent04
echo -e "\n${title}Gen 4 (C4 type):${nc}" | indent04
echo ${ARR_C4[@]} | indent04
echo -e "\n${title}Gen 5 (C5 type):${nc}" | indent04
echo ${ARR_C5[@]} | indent04

echo -e "\n${title}${white}Storage Optimized${nc}: $TOTAL_DHI${nc} Types"
echo -e "\n${title}Dense-storage (D type):${nc}"  | indent04
echo ${ARR_D[@]} | indent04
echo -e "\n${title}Hi-Throughput Gen 3 (H type):${nc}" | indent04
echo ${ARR_H[@]} | indent04
echo -e ${title}"\nHigh I/O (I type):"${nc} | indent04
echo ${ARR_I[@]} | sort | indent04

G_CT=${#ARR_G[@]}
echo -e "\n${title}GPU Graphics Optimized (G type):${nc} $G_CT Types"
echo ${ARR_G[@]} | sort

P_CT=${#ARR_P[@]}
echo -e "\n${title}GPU General Purpose (P type):${nc} $P_CT Types"
echo ${ARR_P[@]} | sort

R_CT=${#ARR_R[@]}
echo -e "\n${title}Memory Optimized (R type):${nc} $R_CT Types"
echo ${ARR_R[@]} | sort

X_CT=${#ARR_X[@]}
echo -e "\n${title}Memory Optimized (X type):${nc} $X_CT Types"
echo ${ARR_X[@]} | sort

F1_CT=${#ARR_F1[@]}
echo -e "\n${title}FPGA Gen 1 (F type):${nc} $F1_CT Types"
echo ${ARR_F1[@]} | sort

MISC_CT=${#ARR_MISC[@]}
echo -e "\n${title}Miscellaneous EC2 instances:${nc} $MISC_CT Types"
echo ${ARR_MISC[@]} | sort
echo -e "\n"


# clean up
clean_up


# <-- end -->
exit 0
