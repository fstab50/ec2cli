#
#   RPM spec: gcreds, 2018 Sept 18
#
%define name        gcreds
%define version     MAJOR_VERSION
%define release     MINOR_VERSION
%define _bindir     usr/local/bin
%define _libdir     usr/local/lib/gcreds
%define _compdir    etc/bash_completion.d
%define _yumdir     etc/yum.repos.d
%define _logdir     var/log
%define _topdir     /home/DOCKERUSER/rpmbuild
%define buildroot   %{_topdir}/%{name}-%{version}

BuildRoot:      %{buildroot}
Name:           %{name}
Version:        %{version}
Release:        %{release}
Summary:        Create and Manage Amazon STS Role Credentials for Amazon Web Services

Group:          Development/Tools
BuildArch:      noarch
License:        GPL
URL:            https://gcreds.readthedocs.io
Source:         %{name}-%{version}.%{release}.tar.gz
Prefix:         /usr
Requires:      DEPLIST

%if 0%{?rhel}%{?amzn2}
Requires: epel-release bash-completion procps-ng jq awscli hostname util-linux coreutils curl bc bash
%endif

%if 0%{?amzn1}
Requires: epel-release procps jq awscli hostname util-linux coreutils curl bc bash
%endif

%description
gcreds requests temporary credentials from Amazon's Security Token Service, STS
(http://docs.aws.amazon.com/STS/latest/APIReference/Welcome.html), for roles that
normally require multi-factor credentials authentication in order to authenticate users.
-
A primary use case for gcreds is the generation of a temporary set of AWS access credentials
for programmatic use by automation tools running on your local machine.
-
gcreds manages temporary credentials it generates to prevent corruption of your local awscli
config. When generating new temporary credentials, gcreds will automatically clear expired
credentials from your local awscli config to prevent duplicate sets of credentials.


%prep


%setup -q

%build


%install
install -m 0755 -d $RPM_BUILD_ROOT/%{_bindir}
install -m 0755 -d $RPM_BUILD_ROOT/%{_libdir}
install -m 0755 -d $RPM_BUILD_ROOT/%{_logdir}
install -m 0755 -d $RPM_BUILD_ROOT/%{_compdir}
install -m 0755 -d $RPM_BUILD_ROOT/%{_yumdir}
install -m 0755 gcreds $RPM_BUILD_ROOT/%{_bindir}/gcreds
install -m 0644 std_functions.sh $RPM_BUILD_ROOT/%{_libdir}/std_functions.sh
install -m 0644 colors.sh $RPM_BUILD_ROOT/%{_libdir}/colors.sh
install -m 0644 colors.py $RPM_BUILD_ROOT/%{_libdir}/colors.py
install -m 0644 iam_users.py $RPM_BUILD_ROOT/%{_libdir}/iam_users.py
install -m 0644 precheck-accounts.py $RPM_BUILD_ROOT/%{_libdir}/precheck-accounts.py
install -m 0644 version.py $RPM_BUILD_ROOT/%{_libdir}/version.py
install -m 0644 gcreds-completion.bash $RPM_BUILD_ROOT/%{_compdir}/gcreds-completion.bash


%files
 %defattr(-,root,root)
/%{_libdir}
/%{_compdir}
/%{_yumdir}
/%{_bindir}/gcreds
%exclude /%{_libdir}/*.pyc
%exclude /%{_libdir}/*.pyo


%post  -p  /bin/bash

BIN_PATH=/usr/local/bin

##  finalize file ownership & permissions  ##

# log file
touch /var/log/gcreds.log
chown root:root /var/log/gcreds.log
chmod 0666 /var/log/gcreds.log


##   ensure /usr/local/bin for python executables in PATH   ##

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


##   enable bash_completion   ##

# - /etc/bash_completion.d
# - /usr/local/etc/bash_completion.d
# - /usr/share/bash-completion/completions

if [[ -f '/etc/bash_completion' ]]; then
    . /etc/bash_completion

elif [[ -d '/etc/bash_completion.d' ]]; then
    . /etc/bash_completion.d/gcreds-completion.bash

elif [[ -f '/usr/share/bash-completion/bash_completion' ]]; then
    . /usr/share/bash-completion/bash_completion

elif [[ -f '/usr/local/etc/bash_completion.d/gcreds-completion.bash' ]]; then
    . /usr/local/etc/bash_completion.d/gcreds-completion.bash
fi


exit 0      ## post install end ##
