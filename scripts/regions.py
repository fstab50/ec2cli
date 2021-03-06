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
from pyaws.session import boto3_session
from botocore.exceptions import ClientError


REGIONLIST = 'regions.list'
CONFIG_DIR = os.getenv('HOME') + '/' + '.config/ec2cli'
REFERENCE = '../core' + REGIONLIST
MAX_AGE_DAYS = 3


# --- declarations  --------------------------------------------------------------------------------


def region_list():
    return [
        'ap-northeast-1',
        'ap-northeast-2',
        'ap-northeast-3',
        'ap-south-1',
        'ap-southeast-1',
        'ap-southeast-2',
        'ca-central-1',
        'eu-central-1',
        'eu-north-1',
        'eu-west-1',
        'eu-west-2',
        'eu-west-3',
        'sa-east-1',
        'us-east-1',
        'us-east-2',
        'us-west-1',
        'us-west-2'
    ]


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
        print('\t\t' + x.strip())


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
    print(f'\n\tRegioncode file ({REGIONLIST}), less than {MAX_AGE_DAYS} days old.\n')
    sys.exit(0)

else:
    regions = get_regions(profile=PROFILE)
    write_file(regions, REFERENCE)

    print('\n\tContents written to core/regions.list:\n')
    print_array(regions)
    print(f'\n\tFile contains {len(regions)} AWS region codes\n')

sys.exit(0)
