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
    # <-- end function _complete_branchdiff_commands -->
}


function _complete_branchdiff_commands(){
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
    # <-- end function _complete_branchdiff_commands -->
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


function _branchdiff_completions(){
    ##
    ##  Completion structures for branchdiff exectuable
    ##
    local numargs numoptions cur prev prevcmd

    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    initcmd="${COMP_WORDS[COMP_CWORD-2]}"
    #echxo "cur: $cur, prev: $prev"

    # initialize vars
    COMPREPLY=()
    numargs=0
    numoptions=0

    # option strings
    commands='--branch --code --commit-log --debug --help --repository-url --version'
    commitlog_subcommands='detail help history summary'
    operations='--branch --code'
    norepo_commands='--help --version'


    case "${initcmd}" in

        '--branch')
            if [ "$(echo "${COMP_WORDS[@]}" | grep '\-\-code')" ] && [ "$(echo "${COMP_WORDS[@]}" | grep '\-\-debug')" ]; then
                return 0

            elif [ "$(echo "${COMP_WORDS[@]}" | grep '\-\-code')" ]; then
                COMPREPLY=( $(compgen -W "--debug" -- ${cur}) )
                return 0

            elif [ "$(echo "${COMP_WORDS[@]}" | grep '\-\-debug')" ]; then
                COMPREPLY=( $(compgen -W "--code" -- ${cur}) )
                return 0

            else
                COMPREPLY=( $(compgen -W "--code --debug" -- ${cur}) )
                return 0
            fi
            ;;

        '--code')
            if [ "$(echo "${COMP_WORDS[@]}" | grep '\-\-branch')" ]; then
                return 0
            else
                COMPREPLY=( $(compgen -W "--branch" -- ${cur}) )
                return 0
            fi
            ;;

        '--commit-log')
           return 0
           ;;
    esac
    case "${cur}" in

        '--version')
            return 0
            ;;

        'branchdiff')
            _complete_branchdiff_commands "${commands}"
            return 0
            ;;

        '--commit-log')
             _complete_commitlog_subcommands "${commitlog_subcommands}"
            #COMPREPLY=( $(compgen -W "${commitlog_subcommands}" -- ${cur}) )
            return 0
            ;;
    esac
    case "${prev}" in

        '--branch')
            remote_branches=$(_remote_branchnames)
            #_complete_alternatebranch_commands "${local_branchnames}"
            COMPREPLY=( $(compgen -W "${remote_branches}" -- ${cur}) )
            return 0
            ;;

        '--code')

            if [ "$cur" = "" ] || [ "$cur" = "-" ] || [ "$cur" = "--" ]; then
                # display full completion subcommands
                _complete_code_subcommands "$(_code_subcommands)"
            else
                changed_files=$(_code_subcommands)
                COMPREPLY=( $(compgen -W "${changed_files}" -- ${cur}) )
            fi
            return 0
            ;;

        '--debug')
            if [ "$(echo "${COMP_WORDS[@]}" | grep '\-\-branch')" ] && [ "$(echo "${COMP_WORDS[@]}" | grep '\-\-code')" ]; then
                return 0

            elif [ "$(echo "${COMP_WORDS[@]}" | grep '\-\-branch')" ]; then
                COMPREPLY=( $(compgen -W "--code" -- ${cur}) )
                return 0

            elif [ "$(echo "${COMP_WORDS[@]}" | grep '\-\-code')" ]; then
                COMPREPLY=( $(compgen -W "--branch" -- ${cur}) )
                return 0
            fi
            ;;

        '--commit-log')
            if [ "$cur" = "" ] || [ "$cur" = "-" ] || [ "$cur" = "--" ]; then
                # display full completion subcommands
                _complete_commitlog_subcommands "${commitlog_subcommands}"
            else
                COMPREPLY=( $(compgen -W "${commitlog_subcommands}" -- ${cur}) )
            fi
            return 0
            ;;

        '--version' | '--help' | '--repository-url')
            return 0
            ;;

        'detail' | 'history' | 'summary')
            # --commit-log subcommands completed; stop
            return 0
            ;;

        "branchdiff")
            if [ "$(_git_root)" ]; then
                if [ "$cur" = "" ] || [ "$cur" = "-" ] || [ "$cur" = "--" ]; then

                    _complete_branchdiff_commands "${commands}"

                else
                    COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
                fi
            else
                COMPREPLY=( $(compgen -W "${norepo_commands}" -- ${cur}) )
            fi
            return 0
            ;;
    esac

    COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )

} && complete -F _branchdiff_completions branchdiff
