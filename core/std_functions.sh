#!/usr/bin/env bash

# error codes
E_DEPENDENCY=1              # exit code if missing required dependency
E_DIR=2                     # exit code if failure to create log dir, log file
E_BADSHELL=3                # exit code if incorrect shell detected
E_AUTHFAIL=5                # exit code if authentication failure
E_BADPROFILE=6              # exit code if profile name/ role not found in local config
E_USER_CANCEL=7             # exit code if user cancel
E_BADARG=8                  # exit code if bad input parameter
E_EXPIRED_CREDS=9           # exit code if temporary credentials no longer valid
E_MISC=11                   # exit code if miscellaneous (unspecified) error

#
VERSION="1.3"


function authenticated(){
    ## validates authentication using iam user or role ##
    local profilename="$1"
    local response
    #
    response=$(aws sts get-caller-identity --profile $profilename 2>&1)
    if [ "$(echo $response | grep Invalid)" ]; then
        std_message "The IAM profile provided ($profilename) failed to authenticate to AWS. Exit (Code $E_AUTH)" "AUTH"
        return 1
    elif [ "$(echo $response | grep found)" ]; then
        std_message "The IAM user or role ($profilename) cannot be found in your local awscli config. Exit (Code $E_BADARG)" "AUTH"
        return 1
    elif [ "$(echo $response | grep Expired)" ]; then
        std_message "The sts temporary credentials for the role provided ($profilename) have expired. Exit (Code $E_AUTH)" "INFO"
        return 1
    else
        return 0
    fi
}


function convert_time(){
    # time format conversion (http://stackoverflow.com/users/1030675/choroba)
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
    #
    # <-- end function convert_time -->
    #
}

function convert_time_months(){
    # time format conversion (http://stackoverflow.com/users/1030675/choroba)
    num=$1
    min=0
    hour=0
    day=0
    mo=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
                ((num=num/24))
                if((num>30)); then
                  ((day=num%31))
                  ((mo=num/30))
              else
                  ((day=num))
              fi
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    if (( $mo > 0 )); then
        echo "$mo"m,"$day"d
    else
        echo "$day"d,"$hour"h,"$min"m
    fi
    #
    # <-- end function convert_time -->
    #
}

function print_header(){
    ## print formatted report header ##
    local title="$1"
    local width="$2"
    local reportfile="$3"
    #
    if (( $(tput cols) > 280 )); then
        printf "%-10s %*s\n" $(echo -e ${frame}) "$(($width - 1))" '' | tr ' ' _ | indent02 > $reportfile
    else
        printf "%-10s %*s" $(echo -e ${frame}) "$(($width - 1))" '' | tr ' ' _ | indent02 > $reportfile
    fi
    echo -e "${bodytext}" >> $reportfile
    echo -ne ${title} >> $reportfile
    echo -e "${frame}" >> $reportfile
    printf '%*s' "$width" '' | tr ' ' _  | indent02 >> $reportfile
    echo -e "${bodytext}" >> $reportfile
}

function print_footer(){
    ## print formatted report footer ##
    local footer="$1"
    local width="$2"
    #
    printf "%-10s %*s\n" $(echo -e ${frame}) "$(($width - 1))" '' | tr ' ' _ | indent02
    echo -e "${bodytext}"
    echo -ne $footer | indent20
    echo -e "${frame}"
    printf '%*s\n' "$width" '' | tr ' ' _ | indent02
    echo -e "${bodytext}"
}

function print_separator(){
    ## prints single bar separator of width ##
    local width="$1"
    echo -e "${frame}"
    printf "%-10s %*s" $(echo -e ${frame}) "$(($width - 1))" '' | tr ' ' _ | indent02
    echo -e "${bodytext}\n"

}

function std_logger(){
    local msg="$1"
    local prefix="$2"
    local log_file="$3"
    #
    if [ ! $prefix ]; then
        prefix="[INFO]"
    fi
    if [ $log_file ]; then
        echo "$prefix: $pkg ($VERSION): failure to call std_logger, $log_file location undefined"
        exit $E_DIR
    else
        return
    fi
    echo "$(date +'%b %d %T') $host $pkg - $VERSION - $msg" >> "$log_file"
}

function std_message(){
    local msg="$1"
    local prefix="$2"
    local format="$3"
    #
    std_logger "$msg" "$prefix"
    [[ $quiet ]] && return
    shift
    pref="----"
    if [[ $1 ]]; then
        pref="${1:0:5}"
        shift
    fi
    if [ $format ]; then
        echo -e "${yellow}[ $cyan$pref$yellow ]$reset  $msg" | indent04
    else
        echo -e "\n${yellow}[ $cyan$pref$yellow ]$reset  $msg\n" | indent04
    fi
}

function std_error(){
    local msg="$1"
    std_logger "[ERROR]: $msg"
    echo -e "\n${yellow}[ ${red}ERROR${yellow} ]$reset  $msg\n" | indent04
}

function std_warn(){
    local msg="$1"
    std_logger "[WARN]: $msg"
    if [ "$3" ]; then
        # there is a second line of the msg, to be printed by the caller
        echo -e "\n${yellow}[ ${red}WARN${yellow} ]$reset  $msg" | indent04
    else
        # msg is only 1 line sent by the caller
        echo -e "\n${yellow}[ ${red}WARN${yellow} ]$reset  $msg\n" | indent04
    fi
}

function std_error_exit(){
    local msg="$1"
    local status="$2"
    std_error "$msg"
    exit $status
}

function environment_info(){
    local msg_header=$1
    local dep=$2
    local version_info
    local awscli_ver
    local boto_ver
    local python_ver
    #
    version_info=$(aws --version 2>&1)
    awscli_ver=$(echo $version_info | awk '{print $1}')
    boto_ver=$(echo $version_info | awk '{print $4}')
    python_ver=$(echo $version_info | awk '{print $2}')
    #
    if [[ $dep == "aws" ]]; then
        std_logger "[$msg_header]: awscli version detected: $awscli_ver"
        std_logger "[$msg_header]: Python runtime detected: $python_ver"
        std_logger "[$msg_header]: Kernel detected: $(echo $version_info | awk '{print $3}')"
        std_logger "[$msg_header]: boto library detected: $boto_ver"

    elif [[ $dep == "awscli" ]]; then
        std_message "awscli version detected: ${accent}${BOLD}$awscli_ver${UNBOLD}${reset}" $msg_header "pprint" | indent04
        std_message "boto library detected: ${accent}${BOLD}$boto_ver${UNBOLD}${reset}" $msg_header "pprint" | indent04
        std_message "Python runtime detected: ${accent}${BOLD}$python_ver${UNBOLD}${reset}" $msg_header "pprint" | indent04

    elif [[ $dep == "os" ]]; then
        std_message "Kernel detected: ${title}$(echo $version_info | awk '{print $3}')${reset}" $msg_header | indent04

    elif [[ $dep == "jq" ]]; then
        version_info=$(jq --version 2>&1)
        std_message "JSON parser detected: ${title}$(echo $version_info)${reset}" $msg_header | indent04

    else
        std_logger "[$msg_header]: detected: $($prog --version | head -1)"
    fi
    #
    #<-- end function environment_info -->
}
