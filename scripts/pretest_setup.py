"""
Test Setup Module -- THIS SHOULD BE REPURPOSED, TRIGGERED BY make-test.sh script
"""
import os
import sys
import time
import json
import inspect
from configparser import ConfigParser
import logging

# aws imports
import boto3
import moto
import pytest
from botocore.exceptions import ClientError, ProfileNotFound

# test imports
sys.path.insert(0, os.path.abspath('../'))
from tests import environment
from keyup.statics import PACKAGE

# global objects
config = ConfigParser()
logger = logging.getLogger()
logger.setLevel(logging.INFO)


# set global Autotag-specific vars
account_number = '123456789012'
TestUsers = ('developer1', 'developer2', 'developer3')
setup_profilename = 'default'

# test module globals
base_path = '/tmp/autotag-tests-%s' % time.time()
version = 'testing-' + base_path
test_assets = 'tests/assets'

# set region default
if os.getenv('AWS_DEFAULT_REGION') is None:
    default_region = 'us-east-2'
    os.environ['AWS_DEFAULT_REGION'] = default_region
else:
    default_region = os.getenv('AWS_DEFAULT_REGION')

ami_id = 'ami-redhat7'
min_count = 1
max_count = 2
ec2_size = 't2.micro'


@moto.mock_ec2
def get_regions():
    ec2 = boto3.client('ec2')
    return [x['RegionName'] for x in ec2.describe_regions()['Regions'] if 'cn' not in x['RegionName']]


@pytest.fixture()
def regionize():
    os.environ['AWS_REGION'] = default_region
    yield
    if default_region is not None:
        os.environ['AWS_REGION'] = default_region
    else:
        del os.environ['AWS_REGION']


@pytest.fixture()
def sts_resource_objects(region=default_region):
    session = boto3.Session(profile_name=setup_profilename)
    client = session.client('sts', region_name=region)
    yield client
    moto.mock_sts().stop()


@pytest.fixture()
def iam_resource_objects(region=default_region):
    session = boto3.Session(profile_name=setup_profilename)
    client = session.client('iam')
    yield client


@pytest.fixture()
def return_reference(filename):
    with open(test_assets + '/' + filename, 'r') as f1:
        f2 = f1.read()
        content = json.loads(f2)
        yield content


@pytest.fixture()
def import_file_object(filepath):
    handle = open(filepath, 'r')
    file_obj = handle.read()
    return file_obj


def tear_down():
    """ Tears down structures setup expressly for testing """
    HOME = os.environ['HOME']
    awscli = HOME + '/.aws/credentials'
    if os.path.isfile(awscli):
        config.read(awscli)
        for profile in config.sections():
            if 'gcreds-dev1' in profile:
                config.pop(profile)
        with open(awscli, 'w') as f1:
            config.write(f1)
        return True
    return False


class PreTestSetup():
    """
    Sets up default AWS Account with all structures to run
    keyup automated testing
    """
    def __init__(self, user_list):
        self.test_users = user_list
        self.policy_arns = []
        if self.setup_complete(user_list[0]) is False:
            complete1 = self.create_users(user_list)
            complete2 = self.create_policies(user_list)
            complete3 = self.assign_policies(user_list)
            complete4 = self.create_keys(user_list)
            r = self.assess_setup(complete1, complete2, complete3, complete4)
            return r
        else:
            return True

    def setup_complete(self, canary):
        """ Determines if setup has occurred """
        iam_client = next(iam_resource_objects())
        users = iam_client.list_users()
        if canary in users:
            logger.info('PreTest Setup already completed. Exit setup')
            return True
        else:
            return False

    def create_users(self, iam_resource_objects, iam_user, profile=setup_profilename):
        """
        Setup for successive tests in this module
        """
        try:
            iam_client = iam_resource_objects
            # create users
            for user in self.test_users:
                r = iam_client.create_user(Path='/', UserName=iam_user)
        except ClientError as e:
            logger.exception(
                "%s: Error while creating test user IAM accounts (Code: %s Message: %s)" %
                (inspect.stack()[0][3], e.response['Error']['Code'],
                 e.response['Error']['Message']))
        return True

    def create_policies(self, users):
        """ Create IAM policies for new test users """
        iam_client = next(iam_resource_objects())
        policy = next(return_reference('iampolicy-AccessKeySelfService.json'))
        try:
            r = iam_client.create_policy(
                    PolicyName='iampolicy-AccessKeySelfService',
                    Path='/',
                    PolicyDocument=str(policy),
                    Description='self manage iam access keys'
                )
            self.policy_arns.append(r['Policy']['Arn'])
        except Exception as e:
            logger.exception('Error while creating IAM policy')
            return False
        return True

    def assign_policies(self, users):
        """ Assign IAM policies to new test users """
        iam_client = next(iam_resource_objects())
        try:
            for user in users:
                for arn in self.policy_arns:
                    r = iam_client.attach_user_policy(UserName=user, PolicyArn=arn)
        except ClientError as e:
            logger.exception('Error while attaching IAM policy')
            return False
        return True

    def create_keys(self, users):
        """ Create initial set of access keys for each test user """
        iam_client = next(iam_resource_objects())
        HOME = os.environ['HOME']
        config.read(HOME + '/.aws/credentials')
        # create keys for each user
        for user in users:
            keys = iam_client.create_access_key(UserName=user)
            access_key = keys['AccessKey']['AccessKeyId']
            secret_key = keys['AccessKey']['SecretAccessKey']
            config[profile]
        # write new keys

    def assess_setup(self, *args):
        for arg in args:
            if arg is False:
                return False
        return True


if ___name__ == '__main__':
    # run setup
    response = PreTestSetup(TestUsers)
    logger.info('End result from PreTestSetup run:  %s' % str(response))
