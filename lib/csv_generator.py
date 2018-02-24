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
import platform
import datetime
from configparser import ConfigParser
import argparse
import inspect
import loggers
from version import VERSION



logger = loggers.getLogger(VERSION)
