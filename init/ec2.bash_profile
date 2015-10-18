# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# run motd
# this is run via /etc/update-motd/30-banner in Amazon Linux

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# --------------------------------------------------------------------------------
# User specific functions (to be loaded first)
# --------------------------------------------------------------------------------
 
function basher() {
     if [[ $1 = 'run' ]]
     then
         shift
         /usr/bin/docker run -e \
             HIST_FILE=/root/.bash_history \
             -v $HOME/.bash_history:/root/.bash_history \
             "$@"
     else
         /usr/bin/docker "$@"
     fi
}

# --------------------------------------------------------------------------------
# User specific variables 
# --------------------------------------------------------------------------------

# AWS 
export AWS_DEFAULT_REGION=us-west-2
export AWS_ACCESS_KEY=XXXXXXXXXXXXX
export AWS_SECRET_KEY=XXXXXXXXXXXXX
export EC2_BASE=/usr/local/ec2    	# location of init scripts
export EC2_REPO=/home/$USER/git         # location of these utilities for $USER
export EC2_HOME=$EC2_BASE/ec2-api-tools-1.6.13.0
export EC2_URL=https://ec2.us-west-2.amazonaws.com
export S3_URL=https://s3.us-west-2.amazonaws.com
export S3=s3-us-west-2.amazonaws.com

# AWS Marketplace Owner IDs
AMAZON=137112412989
CENTOS=679593333241
UBUNTU=099720109477

# Path
PATH=$PATH:$HOME/.local/bin:$HOME/bin:$EC2_HOME/bin
export PATH

# Enable cmd completion for aws tools
complete -C aws_completer aws

# --------------------------------------------------------------------------------
# User specific aliases 
# --------------------------------------------------------------------------------

# User Aliases
alias v="ls -lh"
alias va="ls -lhd .*"
alias du="du -hc"
alias c="clear"
alias vi="vim"
alias ec2a="sh $EC2_REPO/ec2-qv-AMIs.sh"
alias ec2i="sh $EC2_REPO/ec2-qv-instances.sh"
alias ec2s="sh $EC2_REPO/ec2-qv-snapshots.sh"
alias ec2sg="sh $EC2_REPO/ec2-qv-securitygroups.sh"
alias ec2sub="sh $EC2_REPO/ec2-qv-subnets.sh"
alias ec2v="sh $EC2_REPO/ec2-qv-volumes.sh"
alias dockbash='docker run -e HIST_FILE=/root/.bash_history -v=$HOME/.bash_history:/root/.bash_history'
alias docker=basher  

