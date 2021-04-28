#
#   RPM spec: ec2cli, 2018 Sept 18
#
%define name        ec2cli
%define version     MAJOR_VERSION
%define release     MINOR_VERSION
%define _bindir     usr/local/bin
%define _libdir     usr/local/lib/ec2cli
%define _compdir    etc/bash_completion.d
%define _yumdir     etc/yum.repos.d
%define _logdir     var/log
%define _topdir     /home/DOCKERUSER/rpmbuild
%define buildroot   %{_topdir}/%{name}-%{version}

BuildRoot:      %{buildroot}
Name:           %{name}
Version:        %{version}
Release:        %{release}
Summary:        Manage Amazon Web Services' EC2 machines from the command line

Group:          Development/Tools
BuildArch:      noarch
License:        GPL
URL:            https://github.com/fstab50/ec2cli
Source:         %{name}-%{version}.%{release}.tar.gz
Prefix:         /usr
Requires:      DEPLIST

%if 0%{?rhel}%{?amzn2}
Requires: bind-utils bc bash coreutils curl epel-release bash-completion procps-ng jq awscli hostname util-linux python3
%endif

%if 0%{?amzn1}
Requires: bind-utils bc bash coreutils curl epel-release procps jq awscli hostname util-linux
%endif

%description
EC2cli is a utility which allows one to view and manage EC2 machines,
EBS volumes, snapshots, tags, and EC2 spot instances from the linux
command line in Bash.


%prep


%setup -q

%build


%install
install -m 0755 -d $RPM_BUILD_ROOT/%{_bindir}
install -m 0755 -d $RPM_BUILD_ROOT/%{_libdir}
install -m 0755 -d $RPM_BUILD_ROOT/%{_logdir}
install -m 0755 -d $RPM_BUILD_ROOT/%{_compdir}
install -m 0755 -d $RPM_BUILD_ROOT/%{_yumdir}
install -m 0644 colors.sh $RPM_BUILD_ROOT/%{_libdir}/colors.sh
install -m 0644 colors.py $RPM_BUILD_ROOT/%{_libdir}/colors.py
install -m 0644 config.json $RPM_BUILD_ROOT/%{_libdir}/config.json
install -m 0755 ec2cli $RPM_BUILD_ROOT/%{_bindir}/ec2cli
install -m 0644 ec2cli-completion.bash $RPM_BUILD_ROOT/%{_compdir}/ec2cli-completion.bash
install -m 0644 exitcodes.sh $RPM_BUILD_ROOT/%{_libdir}/exitcodes.sh
install -m 0664 components.py $RPM_BUILD_ROOT/%{_libdir}/components.py
install -m 0664 csv_generator.py $RPM_BUILD_ROOT/%{_libdir}/csv_generator.py
install -m 0664 iam_identities.py $RPM_BUILD_ROOT/%{_libdir}/iam_identities.py
install -m 0664 instancetypes.sh $RPM_BUILD_ROOT/%{_libdir}/instancetypes.sh
install -m 0664 loggers.py $RPM_BUILD_ROOT/%{_libdir}/loggers.py
install -m 0644 help_menus.lib $RPM_BUILD_ROOT/%{_libdir}/help_menus.lib
install -m 0664 script_utils.py $RPM_BUILD_ROOT/%{_libdir}/script_utils.py
install -m 0644 oscodes_unix.py $RPM_BUILD_ROOT/%{_libdir}/oscodes_unix.py
install -m 0644 pkgconfig.json $RPM_BUILD_ROOT/%{_libdir}/pkgconfig.json
install -m 0664 spot_prices.sh $RPM_BUILD_ROOT/%{_libdir}/spot_prices.sh
install -m 0644 std_functions.sh $RPM_BUILD_ROOT/%{_libdir}/std_functions.sh
install -m 0644 regions.list $RPM_BUILD_ROOT/%{_libdir}/regions.list
install -m 0644 sizes.txt $RPM_BUILD_ROOT/%{_libdir}/sizes.txt
install -m 0644 version.py $RPM_BUILD_ROOT/%{_libdir}/version.py


%files
 %defattr(-,root,root)
/%{_libdir}
/%{_compdir}
/%{_yumdir}
/%{_bindir}/ec2cli
%exclude /%{_libdir}/*.pyc
%exclude /%{_libdir}/*.pyo


%post  -p  /bin/bash

BIN_PATH=/usr/local/bin

##  finalize file ownership & permissions  ##

# log file
touch /var/log/ec2cli.log
chown root:root /var/log/ec2cli.log
chmod 0666 /var/log/ec2cli.log


##  ensure AWS python3 SDK installed (requires Internet access)  ##

if [ ! $(pip3 list 2>1 | grep boto3) ]; then
    printf -- '\n\tInstalling AWS python3 SDK boto3...\n\n'
    pip=$(which pip3)
    $pip install boto3 2>/dev/null
fi


##  ensure /usr/local/bin for python executables in PATH  ##

if [ ! "$(echo $PATH | grep '\/usr\/local\/bin')" ]; then

    # path updates - root user
    if [[ -f "$HOME/.bashrc" ]]; then
        printf -- '%s\n\n' 'PATH=$PATH:/usr/local/bin' >> "$HOME/.bashrc"
        printf -- '%s\n' 'export PATH' >> "$HOME/.bashrc"

    elif [[ -f "$HOME/.bash_profile" ]]; then
        printf -- '%s\n\n' 'PATH=$PATH:/usr/local/bin' >> "$HOME/.bash_profile"
        printf -- '%s\n' 'export PATH' >> "$HOME/.bash_profile"

    elif [[ -f "$HOME/.profile" ]]; then
        printf -- '%s\n\n' 'PATH=$PATH:/usr/local/bin' >> "$HOME/.profile"
        printf -- '%s\n' 'export PATH' >> "$HOME/.profile"

    fi

    # path updates - sudo user
    if [[ $SUDO_USER ]]; then

        if [[ -f "/home/$SUDO_USER/.bashrc" ]]; then
            printf -- '%s\n\n' 'PATH=$PATH:/usr/local/bin' >> "/home/$SUDO_USER/.bashrc"
            printf -- '%s\n' 'export PATH' >> "/home/$SUDO_USER/.bashrc"

        elif [[ -f "/home/$SUDO_USER/.bash_profile" ]]; then
            printf -- '%s\n\n' 'PATH=$PATH:/usr/local/bin' >> "/home/$SUDO_USER/.bash_profile"
            printf -- '%s\n' 'export PATH' >> "/home/$SUDO_USER/.bash_profile"

        elif [[ -f "/home/$SUDO_USER/.profile" ]]; then
            printf -- '%s\n\n' 'PATH=$PATH:/usr/local/bin' >> "/home/$SUDO_USER/.profile"
            printf -- '%s\n' 'export PATH' >> "/home/$SUDO_USER/.profile"

        fi

    fi
fi


exit 0      ## post install end ##
