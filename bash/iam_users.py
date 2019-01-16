#!/usr/bin/env python3
"""
Summary.

    Prints iam usernames from local awscli configuration.
    A usernames may be omitted from the output simply by
    listing them with a space between them after the call:

    $ python3 iam_users.py default

    Will print all iam usernames in the local configuration
    except the default user (username "default")

"""
import os
import sys
import inspect

try:
    from configparser import ConfigParser
except Exception:
    print('unable to import configParser library. Exit')
    sys.exit(1)


# --- declarations  --------------------------------------------------------------------------------


def print_array(content, args):
    for x in content.sections():
        if x in args:
            continue
        else:
            print(x + ' ', end='')


def shared_credentials_location():
    """
    Summary:
        Discover alterate location for awscli shared credentials file
    Returns:
        TYPE: str, Full path of shared credentials file, if exists
    """
    if 'AWS_SHARED_CREDENTIALS_FILE' in os.environ:
        return os.environ['AWS_SHARED_CREDENTIALS_FILE']
    return ''


def awscli_profiles():
    """Returns IAM usernames from local awscli configuration"""
    if os.path.isfile(config_file):
        config.read(config_file)
    else:
        sys.exit(1)

    for profile in config.sections():
        if 'role_arn' in config[profile].keys() or 'aws_security_token' in config[profile].keys():
            config.pop(profile)
    return config


def print_profiles(config, args):
    """Execution when no parameters provided"""
    try:
        print_array(config, args)
    except OSError as e:
        print('{}: OSError: {}'.format(inspect.stack(0)[3], e))
        return False
    return True


# --- main --------------------------------------------------------------------------------


# globals
home = os.environ.get('HOME')
config_file = shared_credentials_location() or home + '/.aws/credentials'
config = ConfigParser()

modified_config = awscli_profiles()
sys.exit(print_profiles(modified_config, sys.argv[1:]))
