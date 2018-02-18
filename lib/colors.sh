#!/usr/bin/env bash

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
wgray='\033[38;5;95;38;5;251m'          # white-gray
lgray='\033[38;5;95;38;5;245m'          # light gray
dgray='\033[38;5;95;38;5;8m'            # dark gray
reset=$(tput sgr0)

# bright colors
brightblue='\033[38;5;51m'
brightcyan='\033[0;36m'
brightgreen='\033[38;5;95;38;5;46m'
brightyellow='\033[38;5;11m'
brightyellow2='\033[38;5;95;38;5;226m'
brightwhite='\033[38;5;15m'
bluepurple='\033[38;5;68m'

# Initialize ansi colors
title=$(echo -e ${underline})
url=$(echo -e ${underline}${brightblue})
options=$(echo -e ${white})
commands=$(echo -e ${brightcyan})       # use for ansi escape color codes
frame=$(echo -e ${brightgreen})         # use for tables; border faming
bodytext=$(echo -e ${reset}${wgray})    # main body text; set to reset for native xterm

# initialize default color scheme
accent=$(tput setaf 008)                # ansi format
ansi_orange=$(echo -e ${orange})        # use for ansi escape color codes

# accent
bold='\u001b[1m'                        # ansi format
underline='\u001b[4m'                   # ansi format
BOLD=`tput bold`
UNBOLD=`tput sgr0`


# --- declarations  ------------------------------------------------------------


# indent
function indent02() { sed 's/^/  /'; }
function indent04() { sed 's/^/    /'; }
function indent10() { sed 's/^/          /'; }
function indent15() { sed 's/^/               /'; }
function indent18() { sed 's/^/                  /'; }
function indent25() { sed 's/^/                         /'; }
