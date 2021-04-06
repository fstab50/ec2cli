##############################################################################
##                                                                          ##
##    RPM Build Dockerfile: CentOS 8 Base image                             ##
##                                                                          ##
##    Purpose:                                                              ##
##       Build container for rpm package assembly                           ##
##                                                                          ##
##    Dependencies:  file list                                              ##
##      - bashrc                          - colors.sh                       ##
##      - .rpmmacros                      - motd-centos.sh                  ##
##      - docker-buildrpm.sh                                                ##
##                                                                          ##
##    Originally written by:                                                ##
##       "Blake Huber" <blakeca00@@gmail.com>                               ##
##                                                                          ##
##############################################################################

FROM centos:centos8
MAINTAINER The CentOS Project <cloud-ops@centos.org>

RUN yum -y update; yum clean all
RUN yum -y groupinstall "Development Tools"
RUN yum -y install epel-release
RUN yum -y update; yum clean all
RUN yum -y install rpm-build rpmdevtools source-highlight highlight
RUN yum -y install redhat-lsb

RUN yum install -y gcc gcc-c++ \
                   libtool libtool-ltdl \
                   make cmake \
                   git vim figlet \
                   pkgconfig mlocate \
                   sudo wget \
                   automake autoconf \
                   yum-utils  && \
    yum clean all

# enable logging
RUN yum -y install rsyslog rsyslog-doc
RUN systemctl enable rsyslog

# python3 components required for build
RUN yum -y install python3 python3-pip python3-setuptools python3-devel

# user operations
ENV USER1 'builder'

RUN useradd $USER1 -d /home/$USER1 -u 1000 -m -G users,wheel && \
    echo "# macros"                      >  /home/$USER1/.rpmmacros && \
    echo "%_topdir    /home/$USER/rpmbuild" >> /home/$USER1/.rpmmacros && \
    echo "%_sourcedir %{_topdir}"        >> /home/$USER1/.rpmmacros && \
    echo "%_builddir  %{_topdir}"        >> /home/$USER1/.rpmmacros && \
    echo "%_specdir   %{_topdir}"        >> /home/$USER1/.rpmmacros && \
    echo "%_rpmdir    %{_topdir}"        >> /home/$USER1/.rpmmacros && \
    echo "%_srcrpmdir %{_topdir}"        >> /home/$USER1/.rpmmacros

# mount volume here to cp completed rpm to on the host
RUN mkdir /mnt/rpm
VOLUME /mnt/rpm

# configure sudoers
RUN sed -i '/Defaults    secure_path/d' /etc/sudoers
RUN echo "$USER1 ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# rpmbuild deps
RUN cd && rpmdev-setuptree
RUN mv ~/rpmbuild /home/$USER1/

# install developer tools remote yum repository
RUN cd && wget http://awscloud.center/rpm/developer-tools.repo
RUN cd && mv ./developer-tools.repo /etc/yum.repos.d/


# --- end root, begin user setup ----------------------------------------------


# dotfiles, USER1
ADD ./bashrc  /home/$USER1/.bashrc
ADD ./.rpmmacros /home/$USER1/.rpmmacros
ADD ./.gitconfig /home/$USER1/.gitconfig

# configure home for USER1
RUN mkdir -p /home/$USER1/.config/bash
RUN mkdir -p /home/$USER1/git
RUN cd /home/$USER1/git; git clone 'https://blakeca00@bitbucket.org/blakeca00/buildpython3.git'
RUN cd /home/$USER1/git/buildpython3 && git pull && git checkout develop

# bash shell configuration
ADD ./colors.sh /home/$USER1/.config/bash/colors.sh
ADD ./motd-centos.sh /home/$USER1/.config/bash/motd.sh
ADD ./loadavg-flat-layout.sh /home/$USER1/.config/bash/loadavg-flat-layout.sh

# completion actions
RUN chown -R $USER1:$USER1 /home/$USER1


# connectivity
EXPOSE 8080


# environment variables
ENV CONTAINER=rpmbuildD OS=centos DIST=el8


# completion update
RUN yum -y update; yum clean all

##

# end rpm build Dockerfile
