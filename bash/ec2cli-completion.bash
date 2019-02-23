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


function current_branch(){
    ##
    ##  returns current working branch
    ##
    echo "$(git branch 2>/dev/null | grep '\*' | awk '{print $2}')"
}


function _code_subcommands(){
    ##
    ##  returns list of all files changed; relative paths
    ##
    local branch1="master"
    local branch2=$(current_branch)
    local root=$(_git_root)

    declare -a changed
    changed=$(git diff --name-only $branch1..$branch2 | xargs -I '{}' realpath --relative-to=. $root/'{}')
    echo "${changed[@]}"
}


function _git_root(){
    ##
    ##  determines full path to current git project root
    ##
    echo "$(git rev-parse --show-toplevel 2>/dev/null)"
}


function _local_branches(){
    ##
    ##  returns an array of git branches listed by the
    ##  local git repository
    ##
    declare -a local_branches

    local_branches=(  $(git branch 2>/dev/null |  grep -v remotes | cut -c 3-50)  )
    echo "${local_branches[@]}"
    #
    # <--- end function _clean_subcommands --->
}


function _remote_branchnames(){
    ##
    ##  returns an array of git branches listed by the
    ##  remote repository
    ##
    declare -a remotes

    remotes=(  $(git branch -a 2>/dev/null |  grep remotes | tail -n +2 | awk -F '/' '{print $NF}')  )
    echo "${remotes[@]}"
    #
    # <--- end function _clean_subcommands --->
}


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
    local split='5'       # times to split screen width
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
    options='--debug --images --instances --sgroups --subnets --help --profile --region --snapshots --tags --version --volumes --vpc'
    commands='attach create list run'
    norepo_commands='--help --version'


    case "${initcmd}" in

        '--sort')
            return 0
            ;;
    esac
    case "${cur}" in

        '--version')
            return 0
            ;;

        'ec2cli')
            _complete_ec2cli_commands "${commands}"
            return 0
            ;;

        '--commit-log')
            _complete_commitlog_subcommands "${commitlog_subcommands}"
            return 0
            ;;
    esac
    case "${prev}" in

        '--profile')
            python3=$(which python3)
            iam_users=$($python3 "$config_dir/iam_identities.py")

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

                _complete_ec2cli_commands "${options}"

            else
                COMPREPLY=( $(compgen -W "${options}" -- ${cur}) )
            fi
            return 0
            ;;
    esac

    COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )

} && complete -F _ec2cli_completions ec2cli
