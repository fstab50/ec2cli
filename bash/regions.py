#!/usr/bin/env python3
"""
Summary.

    Prints AWS region codes by quering the Amazon APIs

        $ python3 regions.py default

Returns:
    AWS region codes (str). Example:  'us-east-1'
"""
import os
import sys
import inspect
import datetime
from botocore.exceptions import ClientError
from pyaws.session import boto3_session
from pyaws.utils import export_json_object

try:
    from configparser import ConfigParser
except Exception:
    print('unable to import configParser library. Exit')
    sys.exit(1)


CONFIG_DIR = os.getenv('HOME') + '/' + '.config/ec2cli'
REFERENCE = CONFIG_DIR + '/' + 'regions.list'
MAX_AGE_DAYS = 3


# --- declarations  --------------------------------------------------------------------------------


def file_age(filepath, unit='seconds'):
    """
    Summary.

        Calculates file age in seconds

    Args:
        :filepath (str): path to file
        :unit (str): unit of time measurement returned.
    Returns:
        age (int)
    """
    ctime = os.path.getctime(filepath)
    dt = datetime.datetime.fromtimestamp(ctime)
    now = datetime.datetime.utcnow()
    delta = now - dt
    if unit == 'days':
        return round(delta.days, 2)
    elif unit == 'hours':
        round(delta.seconds / 3600, 2)
    return round(delta.seconds, 2)


def get_regions(profile=None):
    """ Return list of all regions """
    try:
        if profile is None:
            profile = 'default'
        client = boto3_session(service='ec2', profile=profile)

    except ClientError as e:
        logger.exception(
            '%s: Boto error while retrieving regions (%s)' %
            (inspect.stack()[0][3], str(e)))
        raise e
    return [x['RegionName'] for x in client.describe_regions()['Regions']]


def print_array(args):
    for x in args:
        print(x.strip() + ' ', end='')


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


def print_profiles(config, args):
    """Execution when no parameters provided"""
    try:
        print_array(config, args)
    except OSError as e:
        print('{}: OSError: {}'.format(inspect.stack(0)[3], e))
        return False
    return True


def read(fname):
    basedir = os.path.dirname(sys.argv[0])
    return open(os.path.join(basedir, fname)).read()


def write_file(object, filepath):
    try:
        with open(filepath, 'w') as f1:
            for i in object:
                f1.write(i + '\n')
    except OSError as e:
        print('Error: {}'.format(e))


# --- main --------------------------------------------------------------------------------


PROFILE = None


# globals
if len(sys.argv) > 1:
    if sys.argv[1] == '--profile':
        PROFILE = sys.argv[2]
if PROFILE is None:
    PROFILE = 'default'

if os.path.exists(REFERENCE) and file_age(REFERENCE, 'days') < MAX_AGE_DAYS:
    r = read(REFERENCE)
    regions = [x for x in r.split('\n') if x]
    sys.exit(print_array(regions))
else:
    regions = get_regions(profile=PROFILE)
    print_array(regions)
    write_file(regions, REFERENCE)
    sys.exit(0)
