#!/usr/bin/env bash

#------------------------------------------------------------------------------
#   Author:  	Blake Huber
#   Purpose: 	ec2cli installer
#   Required:
#               - wget
#               - git
#
#   Description:
#               - suggest run script manually due to use of 'git pull'
#                 ie, your local repos will be merged with remote
#               - script traverses down 2 levels of hierarchy
#                 searching for git repos to update.
#
#------------------------------------------------------------------------------

# ec2cli git repository
repo_url='https://github.com/fstab50/ec2cli.git'

#
# global variables
#
PROJECT='ec2cli'
pkg=$(basename $0)
pkg_path=$(cd $(dirname $0); pwd -P)
installer_log="$pkg_path/installer.log"
pwd=$(pwd .)
git=$(which git)
host=$(hostname)
system=$(uname)
clear=$(which clear)

# Configuration files, ancillary vars
CONFIG_DIR="ec2cli"
CONFIG_ROOT="$HOME/.config"
CONFIG_PATH="$CONFIG_ROOT/$CONFIG_DIR"
CONFIG_PATH_ALT="$HOME/.ec2cli"

# format
white=$(tput setaf 7)
bold='\u001b[1m'
title=$(echo -e ${bold}${white})
reset=$(tput sgr0)

#
# ---  delcarations -----------------------------------------------------------------------------------------
#

# indent
function indent02() { sed 's/^/  /'; }
function indent04() { sed 's/^/    /'; }

function std_logger(){
    local msg="$1"
    local prefix="$2"
    #
    if [ ! $prefix ]; then
        prefix="[INFO]"
    fi
    if [[ ! $installer_log ]]; then
        echo "$prefix: $pkg ($VERSION): failure to call std_logger, $installer_log location undefined"
        exit $E_DIR
    fi
    echo "$(date +'%b %d %T') $host $pkg - $VERSION - $msg" >> "$installer_log"
}

function std_message(){
    local msg="$1"
    local format="$3"
    #
    std_logger "$msg"
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

function precheck(){
    ## test default shell ##
    if [ ! -n "$BASH" ]; then
        # shell other than bash
        std_error_exit "Default shell appears to be something other than bash. Please rerun with bash. Aborting (code $E_BADSHELL)" $E_BADSHELL
    fi

    ## create log dir for ec2cli ##
    if [[ ! -d $pkg_path/logs ]]; then
        if ! mkdir -p "$pkg_path/logs"; then
            echo "$pkg: failed to make log directory: $pkg_path/logs"
            exit $E_NOLOG
        fi
    fi

    ## check for required cli tools ##
    for prog in which git aws ssh awk sed bc wget; do
        if ! type "$prog" > /dev/null 2>&1; then
            std_error_exit "$prog is required and not found in the PATH. Aborting (code $E_DEPENDENCY)" $E_DEPENDENCY
        fi
    done

    ## check if awscli tools are configured ##
    if [[ ! -f $HOME/.aws/config ]]; then
        std_error_exit "awscli not configured, run 'aws configure'. Aborting (code $E_DEPENDENCY)" $E_DEPENDENCY
    fi

    ## check for jq, use system installed version if found, otherwise use bundled ##
    if which jq > /dev/null; then
        jq=$(which jq)
    else
        jq="assets/jq/$system/jq"
        if [[ ! -f $jq ]]; then
            std_error_exit "no viable json parser binary (jq) found, Aborting (code $E_DEPENDENCY)" $E_DEPENDENCY
        fi
    fi

    ## config directories, files ##
    if [ -d $CONFIG_ROOT ]; then
        if [ ! -d $CONFIG_PATH ]; then
            std_logger "[INFO]: Directory CONFIG_PATH ($CONFIG_PATH) not found, creating."
            mkdir $CONFIG_PATH
        fi
    else
        std_logger "[INFO]: Directory CONFIG_ROOT ($CONFIG_ROOT) not found, use alternate."
        if [ ! -d $CONFIG_PATH_ALT ]; then
            std_logger "[INFO]: Directory CONFIG_PATH_ALT ($CONFIG_PATH_ALT) not found, creating."
            mkdir $CONFIG_PATH_ALT
        fi
        CONFIG_PATH=$CONFIG_PATH_ALT
    fi
    #
    # <-- end function ec2cli_precheck -->
    #
}

#
# --- main ---------------------------------------------------------------------------------------------------
#

precheck

# download ec2cli
$clear
std_message "The installer will install ${title}ec2cli${reset} to the current directory where the installer is located." "INFO"
echo -e "\n\n"
read -p "  Is this ok? [quit] " choice
if [ -z $choice ] || [ "$choice" = "q" ]; then
    exit 0
fi

# proceed with install
std_message "Install proceeding.  Downloading files... " "INFO"

# clone repo
$git clone $repo_url

cd $PROJECT
EC2_REPO=$(pwd .)
profile=''

std_message "Locating local bash profile..." "INFO"

if [ -f $HOME/.bashrc ]; then
    std_message "Found .bashrc" INFO
    profile="$HOME/.bashrc"

elif [ -f $HOME/.bash_profile ]; then
    std_message "Found .bash_profile" INFO
    profile="$HOME/.bash_profile"

else
    std_message "Could not find either a .bashrc or .bash_profile.  Creating .bashrc." "INFO"
    read -p "  Is this ok? [quit] " choice
    if [ -z $choice ] || [ "$choice" = "y" ]; then
        exit 0
    fi
    profile="$HOME/.bashrc"
    touch $profile
fi

# update local profile
echo "# inserted by ec2cli installer" >> $profile
echo "export EC2_REPO=$EC2_REPO" >> $profile
echo "export PATH=$PATH:$EC2_REPO" >> $profile

std_message "${title}ec2cli${reset} the directory where ssh\n public keys (.pem files) for ec2 instances are." "INFO"

read -p "  Please enter the directory location: [.]: " choice

if [ -z $choice ]; then
    SSH_KEYS=$EC2_REPO
else
    SSH_KEYS=$choice
fi

echo "export SSH_KEYS=$SSH_KEYS" >> $profile

std_message "${title}ec2cli${reset} Installer Complete. Installer log located at $installer_log." "INFO"
std_message "End.\n" INFO
source $profile
exit 0
