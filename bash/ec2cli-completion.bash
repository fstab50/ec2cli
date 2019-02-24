#!/usr/bin/env bash

# GPL v3 License
#
# Copyright (c) 2018 Blake Huber
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


function _complete_alternatebranch_commands(){
    ##
    ##  Prints all local or remote branches
    ##
    local cmds="$1"
    local split='4'       # times to split screen width
    local ct="0"
    local IFS=$' \t\n'
    local formatted_cmds=( $(compgen -W "${cmds}" -- "${cur}") )

    for i in "${!formatted_cmds[@]}"; do
        formatted_cmds[$i]="$(printf '%*s' "-$(($COLUMNS/$split))"  "${formatted_cmds[$i]}")"
    done

    COMPREPLY=( "${formatted_cmds[@]}")
    return 0
    #
    # <-- end function _complete_ec2cli_commands -->
}


function _complete_ec2cli_commands(){
    local cmds="$1"
    local split='6'       # times to split screen width
    local ct="0"
    local IFS=$' \t\n'
    local formatted_cmds=( $(compgen -W "${cmds}" -- "${COMP_WORDS[1]}") )

    for i in "${!formatted_cmds[@]}"; do
        formatted_cmds[$i]="$(printf '%*s' "-$(($COLUMNS/$split))"  "${formatted_cmds[$i]}")"
    done

    COMPREPLY=( "${formatted_cmds[@]}")
    return 0
    #
    # <-- end function _complete_ec2cli_commands -->
}


function _complete_code_subcommands(){
    local cmds="$1"
    local split='3'       # times to split screen width
    local IFS=$' \t\n'
    local formatted_cmds=( $(compgen -W "${cmds}" -- "${cur}") )

    for i in "${!formatted_cmds[@]}"; do
        formatted_cmds[$i]="$(printf '%*s' "-$(($COLUMNS/$split))"  "${formatted_cmds[$i]}")"
    done

    COMPREPLY=( "${formatted_cmds[@]}")
    return 0
    #
    # <-- end function _complete_code_subcommands -->
}


function _complete_commitlog_subcommands(){
    local cmds="$1"
    local split='3'       # times to split screen width
    local IFS=$' \t\n'
    local formatted_cmds=( $(compgen -W "${cmds}" -- "${cur}") )

    for i in "${!formatted_cmds[@]}"; do
        formatted_cmds[$i]="$(printf '%*s' "-$(($COLUMNS/$split))"  "${formatted_cmds[$i]}")"
    done

    COMPREPLY=( "${formatted_cmds[@]}")
    return 0
    #
    # <-- end function _complete_commitlog_subcommands -->
}


function _complete_region_subcommands(){
    local cmds="$1"
    local split='6'       # times to split screen width
    local ct="0"
    local IFS=$' \t\n'
    local formatted_cmds=( $(compgen -W "${cmds}" -- "${cur}") )

    for i in "${!formatted_cmds[@]}"; do
        formatted_cmds[$i]="$(printf '%*s' "-$(($COLUMNS/$split))"  "${formatted_cmds[$i]}")"
    done

    COMPREPLY=( "${formatted_cmds[@]}")
    return 0
    #
    # <-- end function _complete_region_subcommands -->
}


function _numargs(){
    ##
    ## Returns count of number of parameter args passed
    ##
    local parameters="$1"
    local numargs

    for i in $(echo $parameters); do
        numargs=$(( $numargs + 1 ))
    done
    printf -- '%s\n' "$numargs"
    return 0
}


function _parse_compwords(){
    ##
    ##  Interogate compwords to discover which of the  5 horsemen are missing
    ##
    local add_resources=true
    compwords=("${!1}")
    four=("${!2}")
    onlybone=("${!3}")

    declare -a missing_words

    for key in "${four[@]}"; do
        if [[ ! "$(echo "${compwords[@]}" | grep ${key##*-})" ]]; then
            missing_words=( "${missing_words[@]}" "$key" )
        fi
    done
    for key in "${onlybone[@]}"; do
        if [[ ! "$(echo "${missing_words[@]}" | grep ${key##*-})" ]]; then
            add_resources=false
        fi
    done
    if [[ "$add_resources" = "true" ]]; then
        missing_words=( "${onlybone[@]}"  "${missing_words[@]}" )
    fi
    printf -- '%s\n' "${missing_words[@]}"
}


function _ec2cli_completions(){
    ##
    ##  Completion structures for ec2cli exectuable
    ##
    local commands                  #  commandline parameters (--*)
    local subcommands               #  subcommands are parameters provided after a command
    local image_subcommands         #  parameters provided after --image command
    local numargs                   #  integer count of number of commands, subcommands
    local cur                       #  completion word at index position 0 in COMP_WORDS array
    local prev                      #  completion word at index position -1 in COMP_WORDS array
    local initcmd                   #  completion word at index position -2 in COMP_WORDS array

    config_dir="$HOME/.config/ec2cli"
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    initcmd="${COMP_WORDS[COMP_CWORD-2]}"
    #echxo "cur: $cur, prev: $prev"

    # initialize vars
    COMPREPLY=()
    numargs=0
    numoptions=0

    # option strings
    options='--debug --help --profile --region --version'
    resources='--images --instances --sgroups --subnets --snapshots --tags --volumes --vpcs'
    commands='attach create list run'


    case "${initcmd}" in

        '--profile' | '--region')
            ##
            ##  Return compreply with any of the 5 comp_words that
            ##  not already present on the command line
            ##
            declare -a horsemen singletons
            horsemen=(  '--profile' '--region' '--sort' '--all')
            singletons=( "${resources}" )
            subcommands=$(_parse_compwords COMP_WORDS[@] horsemen[@] singletons[@])
            numargs=$(_numargs "$subcommands")

            if [ "$cur" = "" ] || [ "$cur" = "-" ] || [ "$cur" = "--" ] && (( "$numargs" > 2 )); then
                _complete_4_horsemen_subcommands "${subcommands}"
            else
                COMPREPLY=( $(compgen -W "${subcommands}" -- ${cur}) )
            fi
            return 0
            ;;

        '--sort')
            return 0
            ;;
    esac
    case "${cur}" in

        '--version' | '--help')
            return 0
            ;;

        'ec2cli')
            _complete_ec2cli_commands "${commands}"
            return 0
            ;;
    esac
    case "${prev}" in

        'attach' | 'create' | 'list' | 'run')
            ##
            ##  Return compreply with any of the 5 comp_words that
            ##  not already present on the command line
            ##
            declare -a horsemen singletons
            horsemen=(  '--profile' '--region' '--sort' '--all')
            singletons=( "${resources}" )
            subcommands=$(_parse_compwords COMP_WORDS[@] horsemen[@] singletons[@])
            numargs=$(_numargs "$subcommands")

            if [ "$cur" = "" ] || [ "$cur" = "-" ] || [ "$cur" = "--" ] && (( "$numargs" > 2 )); then
                _complete_4_horsemen_subcommands "${subcommands}"
            else
                COMPREPLY=( $(compgen -W "${subcommands}" -- ${cur}) )
            fi
            return 0
            ;;

        '--instances' | '--images' | '--snapshots' | '--sgroups' | '--subnets' | '--volumes')
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
            ;;

        '--profile')
            python3=$(which python3)
            iam_users=$($python3 "$config_dir/iam_users.py")

            if [ "$cur" = "" ] || [ "$cur" = "-" ] || [ "$cur" = "--" ]; then
                # display full completion subcommands
                _complete_profile_subcommands "${iam_users}"
            else
                COMPREPLY=( $(compgen -W "${iam_users}" -- ${cur}) )
            fi
            return 0
            ;;

        '--version' | '--help')
            return 0
            ;;

        '--region' | "--re*")
            ##  complete AWS region codes
            python3=$(which python3)
            regions=$($python3 "$config_dir/regions.py")

            if [ "$cur" = "" ] || [ "$cur" = "-" ] || [ "$cur" = "--" ]; then

                _complete_region_subcommands "${regions}"

            else
                COMPREPLY=( $(compgen -W "${regions}" -- ${cur}) )
            fi
            return 0
            ;;

        '--sort')
            COMPREPLY=( $(compgen -W "size id date" -- ${cur}) )
            return 0
            ;;


        '--tags')
            if [ "$cur" = "" ] || [ "$cur" = "-" ] || [ "$cur" = "--" ]; then
                # display full completion subcommands
                _complete_code_subcommands "$(_code_subcommands)"
            else
                changed_files=$(_code_subcommands)
                COMPREPLY=( $(compgen -W "${changed_files}" -- ${cur}) )
            fi
            return 0
            ;;

        "ec2cli")
            if [ "$cur" = "" ] || [ "$cur" = "-" ] || [ "$cur" = "--" ]; then

                _complete_ec2cli_commands "${options} ${resources}"

            else
                COMPREPLY=( $(compgen -W "${options} ${resources}" -- ${cur}) )
            fi
            return 0
            ;;
    esac

    COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )

} && complete -F _ec2cli_completions ec2cli
