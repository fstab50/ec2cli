##############################################################################
##                                                                          ##
##    RPM Build Dockerfile: Fedora 30 Base image                            ##
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

FROM fedora:30
MAINTAINER The Fedora Project <fedoraproject.org>

RUN dnf -y update; dnf clean all
RUN dnf -y groupinstall "Development Tools"
RUN dnf -y update; dnf clean all
RUN dnf -y install rpm-build rpmdevtools source-highlight highlight

RUN dnf install -y gcc gcc-c++ \
                   libtool libtool-ltdl \
                   make cmake man \
                   git vim figlet \
                   pkgconfig mlocate \
                   sudo wget \
                   automake autoconf \
                   yum-utils  && \
    dnf clean all

RUN useradd builder -d /home/builder -u 1000 -m -G users,wheel && \
    echo "# macros"                      >  /home/builder/.rpmmacros && \
    echo "%_topdir    /home/builder/rpmbuild" >> /home/builder/.rpmmacros && \
    echo "%_sourcedir %{_topdir}"        >> /home/builder/.rpmmacros && \
    echo "%_builddir  %{_topdir}"        >> /home/builder/.rpmmacros && \
    echo "%_specdir   %{_topdir}"        >> /home/builder/.rpmmacros && \
    echo "%_rpmdir    %{_topdir}"        >> /home/builder/.rpmmacros && \
    echo "%_srcrpmdir %{_topdir}"        >> /home/builder/.rpmmacros

# mount volume here to cp completed rpm to on the host
RUN mkdir /mnt/rpm
VOLUME /mnt/rpm

# configure sudoers
RUN sed -i '/secure_path\ =/d' /etc/sudoers
RUN echo "builder ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# rpmbuild deps
RUN cd && rpmdev-setuptree
RUN mv ~/rpmbuild /home/builder/

ADD ./bashrc  /home/builder/.bashrc
ADD ./.rpmmacros /home/builder/.rpmmacros
ADD ./.gitconfig /home/builder/.gitconfig


EXPOSE 8080


# configure home for builder
RUN mkdir -p /home/builder/.config/bash
ADD ./colors.sh /home/builder/.config/bash/colors.sh
ADD ./motd-fedora30.sh /home/builder/.config/bash/motd.sh
ADD ./loadavg-flat-layout.sh /home/$USER1/.config/bash/loadavg-flat-layout.sh

# set user ownership
RUN chown -R builder:builder /home/builder

# environment variables
ENV CONTAINER=rpmbuild OS=centos DIST=el7

##

# end rpm build Dockerfile
