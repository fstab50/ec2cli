"""
Summary:
    csv_generator (python3) | Generate csv from boto3 json output.

    Resource Types Supported:

        - ec2 snapshots

Author:
    Blake Huber
    Copyright Blake Huber, All Rights Reserved.

License:
    GNU General Public License v3.0 (GPL-3)
    Additional terms may be found in the complete license agreement:
    https://bitbucket.org/blakeca00/ec2cli/src/master/LICENSE.txt

OS Support:
    - RedHat Linux, Amazon Linux, Ubuntu & variants

Dependencies:
    - Requires python3, tested under py3.5 and py3.6
"""

import os
import sys
import datetime
import json
import csv
import pdb
import argparse
import inspect

# aws
import boto3
from botocore.exceptions import ClientError, ProfileNotFound

# pkg
from script_utils import stdout_message, get_account_info
import loggers
from _version import VERSION

# globals
logger = loggers.getLogger(VERSION)
now = datetime.datetime.now().strftime('%Y-%m-%d')


def boto3_session(service, region, profile=None):
    """
    Summary:
        Establishes boto3 sessions, client
    Args:
        :service (str): boto3 service abbreviation ('ec2', 's3', etc)
        :profile (str): profile_name of an iam user from local awscli config
    Returns:
        TYPE: boto3 client object
    """
    try:
        if profile:
            if profile == 'default':
                client = boto3.client(service, region_name=region)
            else:
                session = boto3.Session(profile_name=profile)
                client = session.client(service, region_name=region)
        else:
            client = boto3.client(service, region_name=region)
    except ClientError as e:
        logger.exception(
            "%s: IAM user or role not found (Code: %s Message: %s)" %
            (inspect.stack()[0][3], e.response['Error']['Code'],
             e.response['Error']['Message']))
        raise
    except ProfileNotFound:
        msg = (
            '%s: The profile (%s) was not found in your local config. Exit.' %
            (inspect.stack()[0][3], profile))
        stdout_message(msg, 'FAIL')
        logger.warning(msg)
        sys.exit(exit_codes['EX_NOUSER']['Code'])
    return client


def flattenjson(b, delim):
    val = {}
    for i in b.keys():
        if isinstance(b[i], dict):
            get = flattenjson(b[i], delim)
            for j in get.keys():
                val[i + delim + j] = get[j]
        else:
            val[i] = b[i]

    return val


def retrieve_json(account, profilename, r):
    """ requests json data from aws """
    client = boto3_session(service='ec2', region=r, profile=profilename)

    paginator = client.get_paginator('describe_snapshots')
    response_iterator = paginator.paginate(
            OwnerIds=[account],
            PaginationConfig={'PageSize': 100}
        )
    # page thru, retrieve all snapshots
    container = []
    for page in response_iterator:
        for snapshot_dict in page['Snapshots']:
            # preprocess tags
            if snapshot_dict.get('Tags'):
                tags = {x['Key']:x['Value'] for x in snapshot_dict['Tags']}
            else:
                tags = 'None'

            container.append(
                {
                    'AWS Account': snapshot_dict['OwnerId'],
                    'SnapshotId': snapshot_dict['SnapshotId'],
                    'Description': snapshot_dict['Description'],
                    'StartTime': snapshot_dict['StartTime'].strftime('%Y-%m-%dT%H:%M'),
                    'Encrypted': snapshot_dict['Encrypted'],
                    'Progress': snapshot_dict['Progress'],
                    'State': snapshot_dict['State'],
                    'VolumeID': snapshot_dict['VolumeId'],
                    'VolumeSize': snapshot_dict['VolumeSize'],
                    'Tags': tags
                }
            )
    return container


def init_generator():

    # account info
    region = 'eu-west-1'
    profile = 'gcreds-phht-gen-ra1-pr'
    account_id, account_name = get_account_info(profile=profile)
    output_fname = now + '_snapshots-' + account_name + '.csv'

    # pull data from aws
    data_list = retrieve_json(account=account_id, profilename=profile, r=region)

    # pdb.set_trace()
    # column headers for each row of csv data
    columns = [x for x in data_list[0]]

    # create csv file
    with open(output_fname, 'w') as out_file:
        # csv writer object
        csv_w = csv.writer(out_file)

        # write columns in first row
        csv_w.writerow(columns)

        # iterate thru dictionaries, writing 1 per row
        for row in data_list:
            csv_w.writerow(row.values())

    return True


if __name__ == '__main__':
    r = init_generator()
    logger.info('Response is: %s' % r)
    sys.exit(0)
