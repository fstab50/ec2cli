#!/usr/bin/env bash

#
#   Manual creation of container assets for testing
#

pkg=$(basename $0)
container_default='buildpyCentOS8'
image='centos8:rpmbuildA'


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
        return 1    # container running
    else
        return 0    # container stopped
    fi
}


# --- main -----------------------------------------------------------------


pkg_path=$(cd "$(dirname $0)"; pwd -P)
source "$(_git_root)/scripts/std_functions.sh"
source "$(_git_root)/scripts/colors.sh"


if [ "$1" ]; then
    container="$1"
    std_message "Creating container $container" "OK"

elif [ "$(docker ps -a | grep $container_default)" ]; then
    tab='          '
    std_message "Default container $container_default exists.  You must provide a unique name as a parameter
    \n${tab}$ sh $pkg 'xlinesCentOS'" "FAIL"
    exit 1

else
    container=$container_default
    std_message "Creating default container name:  $container_default" "INFO"
fi

# working directory
cd "$(_git_root)/packaging/docker/centos8" || false

# create image
std_message "Begin image build" "INFO"
docker build  -t  $image .

# create container
std_message "Creating and running container ($container) -- START" "INFO"
docker run -it \
    --user='builder' \
    --security-opt='label=disable' \
    --publish='80:8080' \
    --name=$container -d -v /tmp/rpm:/mnt/rpm $image tail -f /dev/null &

if container_started; then
    std_message "Container ${container} started successfully" "OK"
else
    std_message "Container ${container} failed to start" "FAIL"
fi


# --- closing -----------------------------------------------------------------


#std_message 'Ensuring host docker volume mnt owned by SUDO_USER (/tmp/rpm)' 'INFO'
#sudo chown -R $USER:$USER /tmp/rpm

# clean
std_message 'Cleaning up intermediate image artifacts' 'INFO'
docker image prune -f


cd $pkg_path || true
exit 0
