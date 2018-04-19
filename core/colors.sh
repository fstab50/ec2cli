#!/usr/bin/env bash

#
#   colors.sh module | std colors for bash
#


VERSION="1.6"


# Formatting
blue=$(tput setaf 4)
cyan=$(tput setaf 6)
green=$(tput setaf 2)
purple=$(tput setaf 5)
red=$(tput setaf 1)
white=$(tput setaf 7)
yellow=$(tput setaf 3)
orange='\033[38;5;95;38;5;214m'
gray=$(tput setaf 008)
wgray='\033[38;5;95;38;5;250m'              # white-gray
lgray='\033[38;5;95;38;5;245m'              # light gray
dgray='\033[38;5;95;38;5;8m'                # dark gray
reset=$(tput sgr0)

# bright colors
brightblue='\033[38;5;51m'
brightcyan='\033[0;36m'
brightgreen='\033[38;5;95;38;5;46m'
brightyellow='\033[38;5;11m'
brightyellow2='\033[38;5;95;38;5;226m'
brightyellowgreen='\033[38;5;95;38;5;155m'
brightwhite='\033[38;5;15m'
bluepurple='\033[38;5;68m'

# font format
bold='\u001b[1m'                            # ansi format
underline='\u001b[4m'                       # ansi format
BOLD=`tput bold`
UNBOLD=`tput sgr0`

# Initialize ansi colors
title=$(echo -e ${bold}${white})
url=$(echo -e ${underline}${brightblue})
options=$(echo -e ${white})
commands=$(echo -e ${brightcyan})           # use for ansi escape color codes

# frame codes (use for tables)
gframe=$(echo -e ${brightgreen})            # use for tables; green border faming
bgframe=$(echo -e ${bold}${brightgreen})    # use for tables; green bold border faming
oframe=$(echo -e ${orange})                 # use for tables; orange border faming
boframe=$(echo -e ${bold}${orange})         # use for tables; orange bold border faming
wframe=$(echo -e ${brightwhite})            # use for tables; white border faming
bwframe=$(echo -e ${bold}${brightwhite})    # use for tables; white bold border faming

bodytext=$(echo -e ${reset}${wgray})        # main body text; set to reset for native xterm
bg=$(echo -e ${brightgreen})                # brightgreen foreground cmd
bbg=$(echo -e ${bold}${brightgreen})        # bold brightgreen foreground cmd

# initialize default color scheme
accent=$(tput setaf 008)                    # ansi format
ansi_orange=$(echo -e ${orange})            # use for ansi escape color codes


# --- declarations  ------------------------------------------------------------


# indent, x spaces
function indent02() { sed 's/^/  /'; }
function indent04() { sed 's/^/    /'; }
function indent10() { sed 's/^/          /'; }
function indent15() { sed 's/^/               /'; }
function indent18() { sed 's/^/                  /'; }
function indent20() { sed 's/^/                    /'; }
function indent25() { sed 's/^/                         /'; }
