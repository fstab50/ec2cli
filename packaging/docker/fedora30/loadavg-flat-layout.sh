#!/usr/bin/env bash

pkg=$(basename $0)          # pkg reported in logs will be the basename of the caller
pkg_path=$(cd $(dirname $0); pwd -P)
source $pkg_path/colors.sh

bd=$(echo -e ${bold})
bgn=$(echo -e ${bold}${brightgreen})
gn=$(echo -e ${green})
byl=$(echo -e ${bold}${brightyellow2})
yl=$(echo -e ${yellow})
rd=$(echo -e ${bold}${red})

ONE_MIN=$(cat /proc/loadavg | awk '{print $1}')
FIVE_MIN=$(cat /proc/loadavg | awk '{print $2}')
FIF_MIN=$(cat /proc/loadavg | awk '{print $3}')


# ---  declarations   -----------------------------------------------------------------------------


function set_1min(){
    if (( $(echo "$ONE_MIN <= 1.2" | bc -l) )); then
        ONE_MIN="${bgn}$ONE_MIN${reset}"
        ONE_DESC="(${gn}Low)${reset}"
    elif (( $(echo "$ONE_MIN > 1.2" | bc -l) )) && (( $(echo "$ONE_MIN < 3.0" | bc -l) )); then
        ONE_MIN="${byl}$ONE_MIN${reset}"
        ONE_DESC="(${yl}Med${reset})"
    else
        ONE_MIN="${rd}$ONE_MIN${reset}"
        ONE_DESC="${red}(Hi)${reset}"
    fi
}

function set_5min(){
    if (( $(echo "$FIVE_MIN <= 1.2" | bc -l) )); then
        FIVE_MIN="${bgn}$FIVE_MIN${reset}"
        FIVE_DESC="(${gn}Low)${reset}"
    elif (( $(echo "$FIVE_MIN > 1.2" | bc -l) )) && (( $(echo "$FIVE_MIN < 3.0" | bc -l) )); then
        FIVE_MIN="${byl}$FIVE_MIN${reset}"
        FIVE_DESC="(${yl}Med${reset})"
    else
        FIVE_MIN="${rd}$FIVE_MIN${reset}"
        FIVE_DESC="${red}(Hi)${reset}"
    fi
}

function set_15min(){
    if (( $(echo "$FIF_MIN <= 1.2" | bc -l) )); then
        FIF_MIN="${bgn}$FIF_MIN${reset}"
        FIF_DESC="(${gn}Low)${reset}"
    elif (( $(echo "$FIF_MIN > 1.2" | bc -l) )) && (( $(echo "$FIF_MIN < 3.0" | bc -l) )); then
        FIF_MIN="${byl}$FIF_MIN${reset}"
        FIF_DESC="(${yl}Med${reset})"
    else
        FIF_MIN="${rd}$FIF_MIN${reset}"
        FIF_DESC="${red}(Hi)${reset}"
    fi
}


# ---   main   -----------------------------------------------------------------------------------

# set load average colors per time slice
set_1min
set_5min
set_15min

# formats
tabs='\t      '
ta='  '

FORMAT="$1"
# num spaces from LHS
spaces1="$2"        # values approx
spaces2="$3"

if [[ ! $1 || ! $2 || ! $3 ]]; then
    echo -e "\n  You must enter parameters:\n"
    echo -e "\t \$1: Output Format"
    echo -e "\t \$2: spaces from left for first line"
    echo -e "\t \$3: spaces from left for first line"
    exit 1
fi

# output
if [ "$FORMAT" = "A" ]; then
    echo -e "$tabs ${bd}LOAD AVERAGES${reset}" | indent25
    echo -e "$tabs _________________________________________\n" | indent25
    printf "$tabs 1-min: $ONE_MIN | 5-min$: $FIVE_MIN | 15-min: $FIF_MIN\n\n" | indent25

elif [ "$FORMAT" = "B" ]; then
    # uses spaces parameters above
    text="${bd}LOAD AVERAGES${reset}"; printf "\n%*s%s\n" $spaces1 '' "$text"
    text="_________________________________________"; printf "%*s%s\n\n" $spaces1 '' "$text"
    text="$(printf "$tabs 1-min: $ONE_MIN | 5-min$: $FIVE_MIN | 15-min: $FIF_MIN")"
    printf "%*s%s\n\n" $spaces2 '' "$text"

elif [ "$FORMAT" = "C" ]; then
    # Amazon Linux + neofetch motd
    #   - echo -e "\n"; neofetch | indent02
    #   - sh "$CONFIG_DIR/loadavg-flat-layout.sh" "C" 34 0
    text="${bd}LOAD AVG${reset}:  $(printf "1-min: $ONE_MIN  |  5-min: $FIVE_MIN  |  15-min: $FIF_MIN")"
    printf "%*s%s\n" $spaces2 '' "$text"

elif [ "$FORMAT" = "D" ]; then
    # uses spaces parameters above
    text="_________________________________________"
    printf "%*s%s\n\n" $spaces1 '' "$text"
    text="${bd}LOAD AVERAGES${reset}: $(printf "1-min: $ONE_MIN | 5-min$: $FIVE_MIN | 15-min: $FIF_MIN")"
    printf "%*s%s\n\n" $spaces2 '' "$text"
fi

exit 0
