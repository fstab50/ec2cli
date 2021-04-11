#!/usr/bin/env bash

#------------------------------------------------------------------------------
#
#   Note:  to be used with dependent modules
#
#       - colors.sh
#       - exitcodes.sh
#
#       Dependencies must be sourced from the same calling script
#       as this std_functions.sh
#
#   Global Variables provided by the Caller:
#       - LOG_FILE      # std_logger writes to this file
#       - QUIET         # Value = "true" to supress stdout from these reference functions
#
#------------------------------------------------------------------------------

 # pkg reported in logs will be the basename of the caller
pkg=$(basename $0 2>/dev/null)
pkg_root="$(echo $pkg | awk -F '.' '{print $1}')"       # pkg without file extention
pkg_path=$(cd $(dirname $0 2>/dev/null); pwd -P)
host=$(hostname)
system=$(uname)

# this file
LIB_VERSION="2.9.8"

if [ ! $pkg ] || [ ! $pkg_path ]; then
    echo -e "\n[std_functions.sh]: pkg and pkg_path errors - both are null"
fi


function array2json(){
    ## converts associative array to single-level (no nested keys) json file output ##
    #
    #   Caller syntax:
    #       $ array2json config_dict $config_path/configuration_file
    #
    #   where:
    #       $ declare -A config_dict        # config_dict is assoc array, declared in main script
    #
    local -n array_dict=$1      # local assoc array must use -n opt
    local output_file=$2        # location
    local ct                    # counter
    local max_keys              # num keys in array
    #
    echo -e "{" > $output_file
    ct=1
    max_keys=${#array_dict[@]}
    for key in "${!array_dict[@]}"; do
        if [ $ct == $max_keys ]; then
            # last key, no comma
            echo "\"${key}\": \"${array_dict[${key}]}\"" | indent04 >> $output_file
        else
            echo "\"${key}\": \"${array_dict[${key}]}\"," | indent04 >> $output_file
        fi
        ct=$(( $ct + 1 ))
    done
    echo -e "}" >> $output_file
    #
    # <-- end function array2json -->
}


function authenticated(){
    ## validates authentication using iam user or role ##
    local profilename="$1"
    local response
    local awscli=$(which aws)
    #
    response=$($awscli sts get-caller-identity --profile $profilename 2>&1)
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


function binary_depcheck(){
    ## validate binary dependencies installed
    local check_list=( "$@" )
    local msg
    #
    for prog in "${check_list[@]}"; do
        if ! type "$prog" > /dev/null 2>&1; then
            msg="$prog is required and not found in the PATH. Aborting (code $E_DEPENDENCY)"
            std_error_exit "$msg" $E_DEPENDENCY
        fi
    done
    #
    # <<-- end function binary_depcheck -->>
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
        echo -e "$mo"m,"$day"d
    else
        echo -e "$day"d,"$hour"h,"$min"m
    fi
    #
    # <-- end function convert_time -->
    #
}


function delay_spinner(){
    ##
    ##  Usage:
    ##
    ##      $ long-running-command  &
    ##      $ delay_spinner "  Please wait msg..."
    ##
    ##  Spinner exists when long-running-command completes
    ##
    local PROGRESSTXT
    if [ ! "$1" ]; then
        PROGRESSTXT="  Please wait..."
    else
        PROGRESSTXT="$1"
    fi
    # visual progress marker function
    # http://stackoverflow.com/users/2869509/wizurd
    # vars
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    echo -e "\n\n"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r$PROGRESSTXT[%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf -- '\n\n'
    #
    # <-- end function ec2cli_spinner -->
    #
}


function environment_info(){
    local prefix=$1
    local dep=$2
    local log_file="$3"
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
        std_logger "awscli version detected: $awscli_ver" $prefix $log_file
        std_logger "Python runtime detected: $python_ver" $prefix $log_file
        std_logger "Kernel detected: $(echo $version_info | awk '{print $3}')" $prefix $log_file
        std_logger "boto library detected: $boto_ver" $prefix $log_file

    elif [[ $dep == "awscli" ]]; then
        std_message "awscli version detected: ${accent}${BOLD}$awscli_ver${UNBOLD}${reset}" $prefix $log_file | indent04
        std_message "boto library detected: ${accent}${BOLD}$boto_ver${UNBOLD}${reset}" $prefix $log_file | indent04
        std_message "Python runtime detected: ${accent}${BOLD}$python_ver${UNBOLD}${reset}" $prefix $log_file | indent04

    elif [[ $dep == "os" ]]; then
        std_message "Kernel detected: ${title}$(echo $version_info | awk '{print $3}')${reset}" $prefix $log_file | indent04

    elif [[ $dep == "jq" ]]; then
        version_info=$(jq --version 2>&1)
        std_message "JSON parser detected: ${title}$(echo $version_info)${reset}" $prefix $log_file | indent04

    else
        std_logger "Detected: $($prog --version | head -1)" $prefix $log_file
    fi
    #
    # <<-- end function environment_info -->>
}


function is_installed(){
    ##
    ## validate if binary previously installed  ##
    ##
    local binary="$1"
    local location=$(which $binary 2>/dev/null)

    if [ $location ]; then

        std_message "$binary is installed:  $location" "INFO" $LOG_FILE
        return 0

    else

        return 1

    fi
    #
    #<-- end function is_installed -->
}


function is_float(){
    ##
    ## Checks type for floating point number
    ## see is_number integer type checking
    ##
    local num="$1"
    local regex='^[0-9]+[.][0-9]+?$'

    if [[ $num =~ $regex ]] ; then

        # int or float
        return 0

    fi

    return 1        # not a floating point number
    #
    #<-- end function is_float -->
}


function is_int(){
    ##
    ## see is_float for decimal type checking ##
    ##
    local num="$1"
    local regex='^[0-9]+$'

    if [[ $num =~ $regex ]] ; then

        # int or float
        return 0

    fi

    return 1        # not an integer
    #
    #<-- end function is_int -->
}


function is_number(){
    ##
    ## type checking; any, int or decimal type ##
    ##
    local num="$1"
    local regex='^[0-9]+([.][0-9]+)?$'

    if [[ $num =~ $regex ]] ; then

        # int or float
        return 0

    fi

    return 1        # not a number (is alpha character)
    #
    #<-- end function is_number -->
}


function linux_distro(){
    ##
    ## determine linux os distribution ##
    ##
    local os_major
    local os_release
    local os_codename
    declare -a distro_info

    if [ "$(which lsb_release)" ]; then

        distro_info=( $(lsb_release -sirc) )

        if [[ ${#distro_detect[@]} -eq 3 ]]; then
            os_major=${distro_info[0]}
            os_release=${distro_info[1]}
            os_codename=${distro_info[2]}
        fi

    else

        ## AMAZON Linux ##
        if [ "$(grep -i amazon /etc/os-release  | head -n 1)" ]; then

            os_major="amazonlinux"
            if [ "$(grep VERSION_ID /etc/os-release | awk -F '=' '{print $2}')" = '"2"' ]; then
                os_release="$(grep VERSION /etc/os-release | grep -v VERSION_ID | awk -F '=' '{print $2}')"
                os_release=$(echo $os_release | cut -c 2-15 | rev | cut -c 2-15 | rev)
            elif [ "$(grep VERSION_ID /etc/os-release | awk -F '=' '{print $2}')" = '"1"' ]; then
                os_release="$(grep VERSION /etc/os-release | grep -v VERSION_ID | awk -F '=' '{print $2}')"
                os_release=$(echo $os_release | cut -c 2-15 | rev | cut -c 2-15 | rev)
            else os_release="unknown"; fi

        ## REDHAT Linux ##
        elif [ $(grep -i redhat /etc/os-release  | head -n 1) ]; then

            os_major="redhat"
            os_release="future"

        ## UBUNTU, ubuntu variants ##
        elif [ "$(grep -i ubuntu /etc/os-release)" ]; then

            os_major="ubuntu"
            if [ "$(grep -i mint /etc/os-release | head -n1)" ]; then
                os_release="linuxmint"
            elif [ "$(grep -i ubuntu_codename /etc/os-release | awk -F '=' '{print $2}')" ]; then
                os_release="$(grep -i ubuntu_codename /etc/os-release | awk -F '=' '{print $2}')"
            else
                os_release="unknown"; fi

        ## distribution not determined ##
        else

            os_major="unknown"; os_release="unknown"

        fi

    fi

    # set distribution type in environment
    export OS_DISTRO="$os_major"
    std_logger "Operating system identified as Major Version: $os_major, Minor Version: $os_release" "INFO" $LOG_FILE

    # return major, minor disto versions
    echo -e "$os_major $os_release $os_codename"
    #
    # <<--- end function linux_distro -->>
}


function pkg_info(){
    ##
    ##  displays information about this library module
    ##
    ##     - dependent module colors.sh is located always adjacent
    ##     - sourcing of dep modules must occur after local var to avoid overwrite
    ##       of variable values in this module
    ##
    local version=$LIB_VERSION
    source $pkg_path/colors.sh
    bd=$(echo -e ${bold})
    act=$(echo -e ${a_orange})
    rst=$(echo -e ${reset})

    # generate list of functions
    printf -- '%s\n' "$(declare -F | awk '{print $3}')" > /tmp/.functions
    sum=$(cat /tmp/.functions | wc -l)

    # construct, display help msg output
    cat <<EOM
    ___________________________________________________

    ${title}Bashtools Library${rst}: Standard Functions

    Module Name:        ${cyan}$pkg${rst}
    Module Version:     ${act}$version${rst}
    ___________________________________________________

    Module Contains $sum Functions:

EOM
    # display list of function names in this module
    for l in $(cat /tmp/.functions); do
        printf -- '\t%s %s\n' "-" "$l"
    done
    printf -- '\n'
    rm /tmp/.functions
    #
    # <<-- end function pkg_info -->>
}


function print_header(){
    ##
    ## print formatted report header ##
    ##
    local title="$1"
    local width="$2"
    local reportfile="$3"
    #
    #if (( $(tput cols) > 480 )); then
    #    printf "%-10s %*s\n" $(echo -e ${frame}) "$(($width - 1))" '' | tr ' ' _ | indent02 > $reportfile
    #else
        printf "%-10s %*s" $(echo -e ${frame}) "$(($width - 1))" '' | tr ' ' _ | indent02 > $reportfile
    #fi
    echo -e "${bodytext}" >> $reportfile
    echo -ne ${title} >> $reportfile
    echo -e "${frame}" >> $reportfile
    printf '%*s' "$width" '' | tr ' ' _  | indent02 >> $reportfile
    echo -e "${bodytext}" >> $reportfile
    #
    # <<--- end function print_header -->>
}


function print_footer(){
    ##
    ## print formatted report footer ##
    ##
    local footer="$1"
    local width="$2"

    printf "%-10s %*s\n" $(echo -e ${frame}) "$(($width - 1))" '' | tr ' ' _ | indent02
    echo -e "${bodytext}"
    echo -ne $footer | indent20
    echo -e "${frame}"
    printf '%*s\n' "$width" '' | tr ' ' _ | indent02
    echo -e "${bodytext}"
    #
    # <<--- end function print_footer -->>
}


function print_separator(){
    ##
    ## prints single bar separator of width ##
    ##

    local width="$1"

    echo -e "${frame}"
    printf "%-10s %*s" $(echo -e ${frame}) "$(($width - 1))" '' | tr ' ' _ | indent02
    echo -e "${bodytext}\n"
    #
    # <<--- end function linux_distro -->>
}


function python_version_depcheck(){
    ##
    ## dependency check for a specific version of python binary ##
    ##
    local version
    local version_min="$1"
    local version_max="$2"
    local msg

    local_bin=$(which python3)
    # determine binary version
    version=$($local_bin 2>&1 --version | awk '{print $2}' | cut -c 1-3)

    if (( $(echo "$version > $version_max" | bc -l) )) || (( $(echo "$version < $version_min" | bc -l) )); then

        msg="python version $version detected - must be > $version_min, but < $version_max"
        std_error_exit "$msg" $E_DEPENDENCY

    fi
    #
    # <<-- end function python_depcheck -->>
}


function progress_dots(){
    ##
    ##  Usage:
    ##
    ##      $ long-running-command  &
    ##      $ progress_dots --text "Process XYZ Starting" --end " End xyz"
    ##
    ##      Exists when long-running-command completes
    ##
    ##  Quiet Mode:
    ##      if QUIET = true, runs timer, no stdout printing
    ##
    ##  Dependencies:
    ##      - requires colors.sh (source of indent function)
    ##
    local text
    local endmsg
    local fast
    local width=$(tput cols)
    local stop=$(( $width / 4 ))
    local pid=$!
    local delay="0.1"
    local counter="0"
    local len

    while [ $# -gt 0 ]; do
        case $1 in
            -e | --end)
                endmsg="$2"; shift 2
                ;;

            -f | --fast)
                fast="$2"; shift 2
                ;;

            -t | --text)
                text=$2; shift 2
                ;;
        esac
    done

    if [ ! "$text" ]; then text="Please wait"; fi
    if [ ! "$endmsg" ]; then endmsg="done."; fi

    # print fast dots if short process
    if [ "$fast" = "true" ]; then delay="$(( 1/15 ))"; fi

    # min width of dot pattern
    if [ $stop -lt "80" ]; then stop="80"; fi

    len=${#text}                            # length of text msg, chars
    stopmarker=$stop                        # stop column when not title row
    titlestop=$(( $stop - $len ))           # stop column on text msg row

    # title
    if [[ ! $QUIET ]]; then
        printf -- '\n\n%s' "$text" | indent04
    fi

    # output progress dots
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do

        if [ "$counter" = "0" ]; then
            printf -- '%s' "."
            stop=$titlestop

        elif [ $counter -ge $stop ]; then
            printf -- '\n%s' "." | indent04
            counter="0"
            stop=$stopmarker

        elif [[ ! $QUIET ]]; then
            printf -- '%s' "."
        fi

        sleep $delay
        counter=$(( $counter + 1 ))

    done

    printf -- "  ${endmsg}\n\n"
    #
    # <-- end function ec2cli_spinner -->
    #
}


function python_module_depcheck(){
    ##
    ## validate python library dependencies
    ##
    local check_list=( "$@" )
    local msg

    for module in "${check_list[@]}"; do

        exitcode=$(python3 -c "import $module" > /dev/null 2>&1; echo $?)

        if [[ $exitcode == "1" ]]; then
            # module not imported, not found
            msg="$module is a required python library. Aborting (code $E_DEPENDENCY)"
            std_error_exit "$msg" $E_DEPENDENCY
        fi

    done
    #
    # <<-- end function python_module_depcheck -->>
}


function std_logger(){
    ##
    ##  Summary:
    ##
    ##      std_logger is usually invoked from std_message; ie, all messages
    ##      to stdout are also logged in this function to the log file.
    ##
    ##  Args:
    ##      - msg:      body of the log message text
    ##
    ##      - prefix:   INFO, DEBUG, etc. Note: WARN is handled by std_warn
    ##                  function
    ##
    ##      - log_file: The file to which log messages should be written
    ##
    ##      - version:  Populated if version module exists in
    ##                  pkg_lib. __version__ sourced from within the
    ##                  version module
    ##
    local msg="$1"
    local prefix="$2"
    local log_file="$3"
    local rst=$(echo -e ${RESET})
    local version
    local strip_ansi="false"

    # set prefix if not provided
    if [ ! $prefix ]; then prefix="INFO"; fi

    # set version in logger
    if [ $pkg_lib ] && [ -f $pkg_lib/version.py ]; then
        source "$pkg_lib/version.py"
        version=$__version__

    elif [ "$LIB_VERSION" ]; then
        version=$LIB_VERSION

    elif [ ! "$LIB_VERSION" ]; then
        version="1.0.NA"

    fi

    # write out to log
    if [ ! -f $log_file ]; then

        # create log file
        touch $log_file

        if [ ! -f $log_file ]; then
            echo -e "[$prefix]: $pkg ($version): std_logger failure, $log_file path not writeable"
            exit $E_DIR
        fi

    elif [ "$strip_ansi" = "true" ]; then

        echo -e "$(date +'%Y-%m-%d %T') $host - $pkg - $version - [$prefix]: $msg${rst}" | \
        sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|G|K]//g" >> "$log_file"

    else

        echo -e "$(date +'%Y-%m-%d %T') $host - $pkg - $version - [$prefix]: $msg${rst}" >> "$log_file"

    fi
    #
    # <<--- end function std_logger -->>
}


function std_message(){
    ##
    ## Caller formats:
    ##
    ##   Logging to File | std_message "xyz message" "INFO" "/pathto/log_file"
    ##
    ##   No Logging  | std_message "xyz message" "INFO"
    ##
    local msg="$1"
    local prefix="$2"
    local log_file="$3"
    local format="$4"
    local rst=${reset}

    if [ "$4" ]; then format=''; else format='\n'; fi

    if [ "$3" ]; then
        case "$prefix" in
            'ok' | 'OK' | 'DONE')
                std_logger "$msg" "INFO" "$log_file"
                prefix="OK"
                ;;

            'INSTALLED' | 'AVAILABLE' | 'NOT-FOUND')
                filtered=$(echo $msg | sed 's/[|]//g')
                std_logger "$filtered" "INFO" "$log_file"
                ;;

            *)
                # info log message written to log
                std_logger "$msg" "$prefix" "$log_file"
                ;;
        esac
    fi

    if [[ $QUIET ]]; then return 0; fi

    case "$prefix" in
        'ok' | 'OK')
            echo -e "${format}${yellow}[  $green${BOLD}$prefix${rst}${yellow}  ]${rst}  $msg${format}" | indent04
            ;;

        'INSTALLED')
            echo -e "${format}$green${BOLD}$prefix${rst}  |  $msg${format}" | indent04
            ;;

        'AVAILABLE')
            echo -e "${format}$prefix${rst}  |  $msg${format}" | indent04
            ;;

        'FAIL' | 'ERROR' | 'BAD' | 'N/A')
            echo -e "${format}${yellow}[ ${red}${BOLD}$prefix${rst}${yellow} ]${rst}  $msg${format}" | indent04
            ;;

        'NOT-FOUND')
            echo -e "${format}${red}${BOLD}$prefix${rst}  |  $msg${format}" | indent04
            ;;

        'WARN')
            echo -e "${format}${yellow}[ ${yellow}$prefix${rst}${yellow} ]${rst}  $msg${format}" | indent04
            ;;

        *)
            echo -e "${format}${yellow}[ $cyan$prefix$yellow ]${rst}  $msg${format}" | indent04
            ;;
    esac
    return 0
    #
    # <<-- end function std_message -->>
}


function std_error(){
    local msg="$1"
    std_logger "$msg" "ERROR" $LOG_FILE
    echo -e "\n${yellow}[ ${red}ERROR${yellow} ]$reset  $msg\n" | indent04
    #
    # <<-- end function std_error -->>
}


function std_warn(){
    local msg="$1"
    local log_file="$2"
    local pc="$(echo -e ${a_brightyellow2})"        # prefix color
    local rst="$(echo -e ${reset})"                 # reset code

    if [ $log_file ]; then
        std_logger "$msg" "WARN" $log_file
    fi

    if [ "$3" ]; then
        # there is a second line of the msg, to be printed by the caller
        echo -e "\n${pv_wgray}[${rst} ${pc}WARN${pv_wgray} ]$reset  $msg" | indent04
    else
        # msg is only 1 line sent by the caller
        echo -e "\n${pv_wgray}[${rst} ${pc}WARN${pv_wgray} ]$reset  $msg\n" | indent04
    fi
    #
    # <<-- end function std_warn -->>
}


function std_error_exit(){
    ##
    ##  standard function presents error msg, automatically
    ##  exits error code
    ##
    local msg="$1"
    local status="$2"
    std_error "$msg"
    exit $status
    #
    # <<-- end function std_warn -->>
}


function timer(){
    ## measure total execution runtime ##
    ##
    ##    Usage:
    ##
    ##       @ beginning:
    ##       $ START=$(timer)
    ##
    ##       @ end time:
    ##       $ printf 'Total runtime: %s\n' $(timer $START)
    ##
    if [[ $# -eq 0 ]]; then

        echo $(date '+%s')

    else
        local  stime=$1
        etime=$(date '+%s')

        if [[ -z "$stime" ]]; then stime=$etime; fi

        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%d:%02d:%02d' $dh $dm $ds

    fi
    #
    # <<-- end function timer -->>
}

# print information about this package
if [ "$pkg" = "std_functions.sh" ]; then
    pkg_info
fi
