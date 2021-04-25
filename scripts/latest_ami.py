#!/usr/bin/env python3

"""
Summary:
    Use Amazon Parameter Store to retrieve the latest AMI for
    any of the mainstay OS Types

    See: https://aws.amazon.com/blogs/mt/query-for-the-latest-windows-ami-using-systems-manager-parameter-store/

"""
import os
import json
import argparse
import boto3

# constants
WIN_SERVER='Windows_Server-2016-English-Full-Base'
LINUX_AMAZON='aml1-etc'



 ami=$(echo "$(aws ssm get-parameters --names /aws/service/ami-windows-latest/Windows_Server-2016-English-Full-Base --region us-east-1 --profile hostaudit2)" | jq -r .Parameters[].Value);
