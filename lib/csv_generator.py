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
import argparse
import inspect

# aws
import boto3
from botocore.exceptions import ClientError, ProfileNotFound

# pkg
from script_utils import stdout_message
import loggers
from _version import VERSION



logger = loggers.getLogger(VERSION)
output_fname =


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
    client = boto3_session(service='ec2', region=r, profile=profile)

    paginator = client.get_paginator('describe_snapshots')
    response_iterator = paginator.paginate(
            OwnerIds=[account],
            PaginationConfig={'PageSize': 100}
        )
    # page thru, retrieve all snapshots
    container, json_data = [], {}
    for page in response_iterator:
        #print(page['Snapshots'])
        for snapshot_dict in page['Snapshots']:
             container.append(
                 {
                     'Description': snapshot_dict['Description'],
                     'Encrypted': snapshot_dict['Encrypted'],
                     'OwnerId': snapshot_dict['OwnerId'],
                     'Progress': snapshot_dict['Progress']
                 }
             )
    return container


def init_generator():
    data_list = retrieve_json()

    input = map( lambda x: flattenjson( x, "__" ), input )

    columns = [x for x in data_list[0]]


    with open( output_fname, 'wb' ) as out_file:
        csv_w = csv.writer( out_file )
        csv_w.writerow( columns )

        for i_r in input:
            csv_w.writerow( map( lambda x: i_r.get( x, "" ), columns ) )
    return True


if __name__ == '__main__':
    r = init_generator()
    logger.info('')
