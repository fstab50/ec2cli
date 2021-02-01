#!/usr/bin/env bash

#
#   Manual creation of container assets for testing
#

pkg=$(basename $0)
container_default='AML2test'
image='amazonlinux:rpmbuildA'


function _git_root(){
    ##
    ##  determines full path to current git project root
    ##
    echo "$(git rev-parse --show-toplevel 2>/dev/null)"
}


function container_started(){
    ##
    ##  check container status
    ##
    if [[ "$(docker ps | grep $container 2>/dev/null)" ]]; then
        return 1    # scontainer running
    else
        return 0    # container stopped
    fi
}


pkg_path=$(cd "$(dirname $0)"; pwd -P)
source "$(_git_root)/scripts/std_functions.sh"
source "$(_git_root)/scripts/colors.sh"


if [ "$1" ]; then
    container="$1"
    std_message "Creating container $container" "OK"

elif [ "$(docker ps -a | grep $container_default)" ]; then
    tab='          '
    std_message "Default container $container_default exists.  You must provide a unique name as a parameter
    \n${tab}$ sh $pkg 'AML2test2'" "FAIL"
    exit 1

else
    container=$container_default
    std_message "Creating default container name:  $container_default" "INFO"
fi

# working directory
cd "$(_git_root)/packaging/docker/amazonlinux2" || false

# create image
std_message "Begin image build" "INFO"
docker build  -t  $image .

# create container
std_message "Creating and running container ($container) -- START" "INFO"
docker run -it --user='builder' --name=$container -d -v /tmp/rpm:/mnt/rpm $image tail -f /dev/null &

if container_started; then
    std_message "Container ${container} started successfully" "OK"
else
    std_message "Container ${container} failed to start" "FAIL"
fi

# clean
std_message 'Cleaning up intermediate image artifacts' 'INFO'
docker image prune -f


cd $pkg_path || true
exit 0
