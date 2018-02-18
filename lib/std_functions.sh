#!/usr/bin/env bash


function print_header(){
    ## print formatted report header ##
    local title="$1"
    local width="$2"
    local reportfile="$3"
    #
    printf "%-10s %*s" $(echo -e ${frame}) "$(($width - 1))" '' | tr ' ' _ | indent02 > $reportfile
    echo -e "${bodytext}" >> $reportfile
    echo -ne ${title} >> $reportfile
    echo -e "${frame}" >> $reportfile
    printf '%*s' "$total_width" '' | tr ' ' _  | indent02 >> $reportfile
    echo -e "${bodytext}" >> $reportfile
}

function print_footer(){
    ## print formatted report footer ##
    local footer="$1"
    #
    printf "%-10s %*s\n" $(echo -e ${frame}) "$(($width - 1))" '' | tr ' ' _ | indent02
    echo -e "${bodytext}"
    echo -ne $footer | indent10
    echo -e "${frame}"
    printf '%*s\n' "$total_width" '' | tr ' ' _ | indent02
    echo -e "${bodytext}"
}

function print_separator(){
    ## prints single bar separator of width ##
    local width="$1"
    echo -e "${frame}"
    #printf '%*s\n' "$total_width" '' | tr ' ' _ | indent02
    printf "%-10s %*s" $(echo -e ${frame}) "$(($width - 1))" '' | tr ' ' _ | indent02
    echo -e "${bodytext}\n"

}
