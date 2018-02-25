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
from script_utils import boto3_session, stdout_message, get_account_info
from oscodes_unix import exit_codes
import loggers
from _version import __version__

# globals
logger = loggers.getLogger(__version__)
now = datetime.datetime.now().strftime('%Y-%m-%d')


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


def options(parser, help_menu=False):
    """
    Summary:
        parse cli parameter options
    Returns:
        TYPE: argparse object, parser argument set
    """
    parser.add_argument("-p", "--profile", nargs='?', default="default",
                              required=True, help="type (default: %(default)s)")
    parser.add_argument("-r", "--region", nargs='?', required=True)
    parser.add_argument("-f", "--filepath", nargs='?', required=False)
    parser.add_argument("-d", "--debug", dest='debug', action='store_true', required=False)
    return parser.parse_args()


def init():

    parser = argparse.ArgumentParser(add_help=True, description="csv_generator help:")

    try:
        args = options(parser)
    except Exception as e:
        stdout_message(str(e), 'ERROR')
        sys.exit(exit_codes['EX_OK']['Code'])

    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(exit_codes['EX_OK']['Code'])

    # account info
    account_id, account_name = get_account_info(profile=args.profile)

    # file info
    output_fname = now + '_snapshots-' + account_name + '.csv'
    if args.path:
        if args.path.endswith('/'):
            path = '/'.join(args.path.split('/')[:-1])
        else:
            path = args.path
        output_filepath = path + '/' + output_fname
    else:
        output_filepath = os.environ['HOME'] + '/Downloads/' + output_fname

    # pull data from aws
    data_list = retrieve_json(account=account_id, profilename=args.profile, r=args.region)

    # pdb.set_trace()
    # column headers for each row of csv data
    columns = [x for x in data_list[0]]
    try:
        # create csv file
        with open(output_filepath, 'w') as out_file:
            # csv writer object
            csv_w = csv.writer(out_file)

            # write columns in first row
            csv_w.writerow(columns)

            # iterate thru dictionaries, writing 1 per row
            for row in data_list:
                csv_w.writerow(row.values())
    except OSError as e:
        msg = 'Could not write to file or other OS-level error was encountered.'
        logger.exception('%s: %s' % (inspect.stack()[0][3], msg, str(e)))
    except Exception as e:
        logger.exception(
            '%s: Problem when creating csv file. (Code: %s)' %
            (inspect.stack()[0][3], str(e)))
    return output_filepath


if __name__ == '__main__':
    file_created = init()
    logger.info('SUCCESS: Created csv file %s' % file_created)
    sys.exit(0)
