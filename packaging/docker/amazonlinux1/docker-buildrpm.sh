#!/usr/bin/env bash

##
##  Docker Build Script
##
##     - Name:     docker-buildrpm.sh
##     - Purpose:  Perform docker-resident configuration steps
##     - Author:   Blake Huber
##     - Log:      /home/builder/logs/dockerbuild.log
##     - Caller:   buildrpm.py (host)
##
##  Copyright 2017-2018 Blake Huber.  All rights reserved.
##


# --- globals --------------------------------------------------------------------------------------

pkg=$(basename $0)                                  # pkg (script) full name
pkg_root=$(echo $pkg | awk -F '.' '{print $1}')     # pkg without file extention
pkg_path=$(cd $(dirname $0); pwd -P)                # location of pkg
TMPDIR='/tmp'
username="builder"
home_dir="$(echo $HOME)"
NOW=$(date +'%Y-%m-%d')
BUILDDIR="$HOME/rpmbuild"
VOLMNT="/mnt/rpm"
LOG_DIR="$HOME/logs"
LOG_FILE="$LOG_DIR/$pkg_root.log"
QUIET="false"

# colors
brightwhite='\033[38;5;15m'
cyan=$(tput setaf 6)
green=$(tput setaf 2)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
BOLD='\u001b[1m'                                    # ansi format
bold='\u001b[1m'                                    # ansi format
underline='\u001b[4m'                               # ansi format

# formatting
title=$(echo -e ${bold}${brightwhite})              # title color, white + bold
ul=$(echo -e ${underline})                          # std underline
bd=$(echo -e ${bold})                               # std bold
wt=$(echo -e ${brightwhite})                        # help menu accent 2
fs=$(echo -e ${yellow})                             # file path color
reset='\u001b[0m'                                   # clear accents; return terminal colors

# exit codes
E_OK=0                             # exit code if normal exit conditions
E_DEPENDENCY=1                     # exit code if missing required ec2cdependency
E_NOLOG=2                          # exit code if failure to create log dir, log file
E_BADSHELL=3                       # exit code if incorrect shell detected
E_AUTH=4                           # exit code if authentication failure
E_USER_CANCEL=7                    # exit code if user cancel
E_BADARG=8                         # exit code if bad input parameter
E_NETWORK_ACCESS=9                 # exit code if no network access from current location
E_EXPIRED_CREDS=10                 # exit code if temporary credentials no longer valid
E_MISC=11                          # exit code if miscellaneous (unspecified) error


# --- declarations ---------------------------------------------------------------------------------


function help_menu(){
    cat <<EOM
        --quiet flag
EOM
}


function binary_depcheck(){
    ##
    ## exit if binary dependencies not installed ##
    ##
    local check_list=( "$@" )
    local msg

    for prog in "${check_list[@]}"; do

        if ! type "$prog" > /dev/null 2>&1; then
            msg="$prog is required and not found in the PATH. Aborting (code $E_DEPENDENCY)"
            std_error_exit "$msg" $E_DEPENDENCY
        fi

    done
    #
    # <<-- end function binary_depcheck -->>
}


function depcheck(){
    ##
    ## dependency check ##
    ##
    local log_dir="$1"
    local log_file="$2"
    local msg

    ## test default shell ##
    if [ ! -n "$BASH" ]; then
        # shell other than bash
        msg="Default shell appears to be something other than bash. Please rerun with bash. Aborting (code $E_BADSHELL)"
        printf -- "\n%s\n" "$msg"
    fi

    ## logging prerequisites  ##
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
        if [ ! "$log_dir" ]; then
            printf -- "\n%s: failed to make log directory: %s. Exit\n" % $pkg $log_dir
        fi

    elif [ ! -f $log_file ]; then
        if ! touch $log_file 2>/dev/null; then
            printf -- "\n%s: failed to seed log file: %s. Exit\n" % $pkg $log_file
        fi
    fi

    ## check for required cli tools ##
    binary_depcheck rpmbuild

    # success
    std_logger "$pkg: dependency check satisfied." "INFO" $log_file
    return 0
    #
    # <<-- end function depcheck -->>
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
    ##      - prefix:   INFO, DEBUG, etc. Note: WARN is handled by std_warn function
    ##      - log_file: The file to which log messages should be written
    ##      - version:  Populated if version module exists in pkg_lib. __version__ sourced
    ##                  from within the version module
    ##
    local msg="$1"
    local prefix="$2"
    local log_file="$3"
    local version

    # set prefix if not provided
    if [ ! $prefix ]; then
        prefix="INFO"
    fi

    # set version in logger
    if [ $pkg_lib ] && [ -f $pkg_lib/version.py ]; then
        source "$pkg_lib/version.py"
        version=$__version__

    elif [ "$VERSION" ]; then
        version=$VERSION

    elif [ ! "$VERSION" ]; then
        version="1.0.NA"

    fi

    # write out to log
    if [ ! -f $log_file ]; then

        # create log file
        touch $log_file

        if [ ! -f $log_file ]; then
            echo -e "[$prefix]: $pkg ($version): failure to call std_logger, $log_file location not writeable"
            exit $E_DIR
        fi

    else

        echo -e "$(date +'%Y-%m-%d %T') $host - $pkg - $version - [$prefix]: $msg" >> "$log_file"

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

    if [ $log_file ] && { [ "$prefix" = "ok" ] || [ "$prefix" = "OK" ]; }; then

        # ensure info log message written to log
        std_logger "$msg" "INFO" "$log_file"

    elif [ $log_file ]; then

        std_logger "$msg" "$prefix" "$log_file"

    fi

    [[ $QUIET ]] && return
    shift
    pref="----"

    if [[ $1 ]]; then
        pref="${1:0:5}"
        shift
    fi

    # output
    if [ $format ]; then

        echo -e "${yellow}[ $cyan$pref$yellow ]$reset  $msg" | indent04

    elif [ "$prefix" = "OK" ] || [ "$prefix" = "ok" ]; then

        echo -e "\n${yellow}[  $green${BOLD}$pref${rst}${yellow}  ]${rst}  $msg\n" | indent04

    else

        echo -e "\n${yellow}[ $cyan$pref$yellow ]${rst}  $msg\n" | indent04

    fi
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
    local byl="$(echo -e ${brightyellow2})"
    local rst="$(echo -e ${reset})"

    std_logger "$msg" "WARN" $LOG_FILE

    if [ "$3" ]; then
        # there is a second line of the msg, to be printed by the caller
        echo -e "\n${yellow}[${rst} ${byl}WARN${yellow} ]$reset  $msg" | indent04
    else
        # msg is only 1 line sent by the caller
        echo -e "\n${yellow}[${rst} ${byl}WARN${yellow} ]$reset  $msg\n" | indent04
    fi
    #
    # <<-- end function std_warn -->>
}


function std_error_exit(){
    ##
    ##  standard function presents error msg, automatically
    ##  exits error code
    local msg="$1"
    local status="$2"
    std_error "$msg"
    exit $status
    #
    # <<-- end function std_warn -->>
}


# -- main -----------------------------------------------------------------------------------------

depcheck $LOG_DIR $LOG_FILE

cd ~

# place spec file
cp ~/buildpy.spec $BUILDDIR/SPECS/
std_message "cp specfile to build dir. Contents of target dir: $(ls -lh $BUILDDIR/SPECS)" "INFO" $LOG_FILE

# create sources
cp ~/buildpy*.tar.gz $BUILDDIR/SOURCES/
std_message "cp TARfile to build dir. Contents of target dir: $(ls -lh $BUILDDIR/SOURCES)" "INFO" $LOG_FILE

cd ~/rpmbuild
std_message "Changed to rpmbuild working directory. (PWD: $PWD)" "INFO" $LOG_FILE

# build rpm
rpmbuild -ba SPECS/buildpy.spec
std_message "executed rpmbuild" "INFO" $LOG_FILE

std_message "copy completed rpm to volume mount: $VOLMNT" "INFO" $LOG_FILE
cp -rv RPMS $VOLMNT >> $LOG_FILE

std_message "rpmbuild Complete. Exit" "INFO" $LOG_FILE


exit 0      # << -- end --- >>
