#!/usr/bin/env python3.6

import os
import sys
import platform
import json
import zipfile
import distutils
import subprocess

from shutil import copytree
from shutil import copy
from logging import getLogger
logger = getLogger()

if os.environ.get('LC_CTYPE', '') == 'UTF-8':
    os.environ['LC_CTYPE'] = 'en_US.UTF-8'

# root user is mandatory to run this script
if (platform.system() == "Linux" or platform.system() == "Darwin") and not os.geteuid() == 0:
    logger.error("Only root can run this script\nUse sudo")
    sys.exit(255)

try:
    if 'ec2' == subprocess.getoutput('head -c 3 /sys/hypervisor/uuid'):

        os.environ['no_proxy']='169.254.169.254'

        try:
            if os.environ['http_proxy']:
                print("http_proxy set with value : ", os.environ['http_proxy'])
            if os.environ['https_proxy']:
                print("https_proxy set with value : ", os.environ['https_proxy'])
        except KeyError as ke:
              if os.path.exists('/etc/profile.d/proxy.sh'):
                  bash_proxy_conf = open('/etc/profile.d/proxy.sh', 'r').read()
                  os.environ['http_proxy'] = bash_proxy_conf.split('\n')[0].split(' ')[1].split('=')[1]
                  os.environ['https_proxy'] = bash_proxy_conf.split('\n')[0].split(' ')[1].split('=')[1]
              else:
                  logger.error("Proxy is not set. Please check your environment or contact your system administrator.")
                  sys.exit(255)

    import pip

    pip.main(['install', 'awscli', '-q'])
    pip.main(['install', 'boto3', '-q'])
    pip.main(['install', 'arghandler', '-q'])
    pip.main(['install', 'requests', '-q'])

except ModuleNotFoundError:
    logger.error("Please install pip for python 3.6")
    sys.exit(255)

import arghandler
import requests

import boto3
from botocore.exceptions import ClientError
from botocore.exceptions import ParamValidationError

AWS_CONFIG_FILE=".aws/config"
S3_BUCKET_REGION='eu-west-1'


def loadEC2InstanceInformation():
    response = requests.get("http://169.254.169.254/latest/dynamic/instance-identity/document",
                            proxies={"http": None})
    return json.loads(response.text)

def get_gcreds_from_s3(credentials=None):
    if credentials is None:
        s3_client = boto3.client('s3')
    else:
        s3_session = boto3.Session(aws_access_key_id=credentials['Credentials']['AccessKeyId'],
                                   aws_secret_access_key=credentials['Credentials']['SecretAccessKey'],
                                   aws_session_token=credentials['Credentials']['SessionToken'],
                                   region_name=S3_BUCKET_REGION)
        s3_client = s3_session.client('s3')

    ec2_env = {"102512488663" : "dev",
               "935229214006" : "qa",
               "872277419998" : "pr" }

    # Default is production # TO CHANGE TO PRODUCTION WHEN VERSION WILL BE CREATED
    s3_bucket_env = 'qa'

    # On AWS EC2 intances, uising env specific
    if 'ec2' == subprocess.getoutput('head -c 3 /sys/hypervisor/uuid'):
        accountId = loadEC2InstanceInformation()["accountId"]
        if accountId in ec2_env:
            s3_bucket_env = ec2_env[accountId]

    s3_bucket_name='s3-%s-mpc-install-%s' % (S3_BUCKET_REGION, s3_bucket_env)
    gcreds_s3_bucket_prefix='utilities/gcreds'

    get_last_modified = lambda obj: int(obj['LastModified'].strftime('%s'))
    objs = [obj for obj in s3_client.list_objects_v2(Bucket=s3_bucket_name, Prefix=gcreds_s3_bucket_prefix)['Contents'] if 'zip' in obj['Key']]
    last_added = [obj['Key'] for obj in sorted(objs, key=get_last_modified, reverse=True)][0]
    code_path = last_added.split('/')[2]
    s3_client.download_file(s3_bucket_name, last_added, code_path)
    return code_path

def get_profile_account_list(credentials):
    print("Getting account list to generate aws profiles")
    dynamodb_session = boto3.Session(aws_access_key_id=credentials['Credentials']['AccessKeyId'],
                               aws_secret_access_key=credentials['Credentials']['SecretAccessKey'],
                               aws_session_token=credentials['Credentials']['SessionToken'],
                               region_name=S3_BUCKET_REGION)

    dynamodb_client = dynamodb_session.client('dynamodb')

    response = dynamodb_client.scan(
        FilterExpression='Prefix = :prefix and (MPCPackage = :ata or MPCPackage = :pkgc)',
        ExpressionAttributeValues={
            ':prefix': {
                'S': 'Atos',
            },
            ':ata': {
                'S': 'ATA',
            },
            ':pkgc': {
                'S': 'RA-PKG-C',
            },
        },
        TableName='MPCAWS_Accounts_List',
    )

    return response['Items']

def update_gcreds_on_linux_like_os(code_path):
    if not os.path.isdir("/opt/gcreds"):
        logger.warning("gcreds was not installed. Installing")
        install_gcreds_on_linux_like_os(code_path)
    else:
        print("Updating gcreds")
        if os.path.isdir(code_path):
            print("  * Copying sources")
            os.remove("/opt/gcreds/gcreds")
            copy("%s/gcreds" % code_path, "/opt/gcreds/")
            os.system("rm -rf /opt/gcreds/modules")
            copytree("%s/modules" % code_path, "/opt/gcreds/modules/")
        else:
            print("  * Unzipping gcreds")
            os.makedirs("/opt/gcreds")
            zip_ref = zipfile.ZipFile(code_path, 'r')
            os.remove("/opt/gcreds/gcreds")
            zip_ref.extractall("gcreds", "/opt/gcreds")
            os.system("rm -rf /opt/gcreds/modules")
            zip_ref.extractall("/opt/gcreds", "modules")
            zip_ref.close()

            os.remove(code_path)

def install_gcreds_on_linux_like_os(code_path):
    if os.path.isdir("/opt/gcreds"):
        logger.error("gcreds already installed. Did you want to update 'gcreds-install update'?")
        sys.exit(255)
    else:
        print("Installing gcreds")
        if os.path.isdir(code_path):
            print("  * Copying sources")
            copytree(code_path, "/opt/gcreds/")
        else:
            print("  * Unzipping gcreds")
            os.makedirs("/opt/gcreds")
            zip_ref = zipfile.ZipFile(code_path, 'r')
            zip_ref.extractall("/opt/gcreds")
            zip_ref.close()

            os.remove(code_path)

        os.chmod("/opt/gcreds/gcreds", 0o755)

        os.makedirs("/opt/gcreds/logs")
        os.chmod("/opt/gcreds/logs", 0o777)

        os.symlink("/opt/gcreds/gcreds", "/usr/local/bin/gcreds")

        print("Installation done successfully")

def createAWSConfigurationFiles(userPath, gcredsUser, gcredsUserGroup):
    if not os.path.isdir(userPath):
        logger.error("ERROR: User %s does not exist.\n       Please contact environment adiministrator" % gcredsUser)
        sys.exit(255)

    if not os.path.isdir("%s/.aws" % userPath):
        os.makedirs("%s/.aws" % userPath)

    if not os.path.exists("%s/%s" % (userPath, AWS_CONFIG_FILE)):
        open("%s/%s" % (userPath, AWS_CONFIG_FILE), 'a').close()

    if not os.path.exists("%s/.aws/credentials" % userPath):
        open("%s/.aws/credentials" % userPath, 'a').close()

    # Change AWS files owner
    os.system('chown -R "%s:%s" %s' % (gcredsUser, gcredsUserGroup, userPath))

@arghandler.subcmd('developer', help='Install gcreds for developers on Local machine')
def developer(parser, context, args):
    parser.add_argument('-z','--zip-file',required=False)
    parser.add_argument('-s','--source',required=False)
    parser.add_argument('-U','--update',required=False,action="store_true")
    args = parser.parse_args(args)

    # Check if awscli is configured
    dasid_answer = input('Provide your DAS ID: ')
    if dasid_answer is None:
        logger.error("DAS ID cannot be empty. Aborting installation")
        sys.exit(255)

    if platform.system() == "Linux":
        gcredsUser = os.environ['SUDO_USER']
        userPath = "/home/%s" % os.environ['SUDO_USER']
    elif platform.system() == "Darwin":
        gcredsUser = os.environ['SUDO_USER']
        userPath = "/Users/%s" % os.environ['SUDO_USER']
    elif "CYGWIN" in platform.system():
        gcredsUser = os.environ['USER']
        userPath = "/home/%s" % os.environ['USER']
    else:
        logger.error("gcreds-install not yet implemented for %s." % platform.system())
        sys.exit(255)

    os.environ["AWS_CONFIG_FILE"] = "%s/.aws/config" % userPath
    os.environ["AWS_SHARED_CREDENTIALS_FILE"] = "%s/.aws/credentials" % userPath


    configured = False
    not_well_configured = False
    while not configured:
        if not os.path.exists("%s/%s" % (userPath, AWS_CONFIG_FILE)) or not_well_configured:
            print("%s/%s does not exist." % (userPath, AWS_CONFIG_FILE))
            answer = input('\nawscli is not %s configured. Configuration is mandatory, answer no will aboard installation. Do you want to configure now? (Y/n): ' % ("well" if not_well_configured else "")).lower()
            if answer == 'n':
                logger.error("ERROR: awscli is not configured, run 'aws configure'. Aborting installation")
                sys.exit(255)
            else:
                # configure user profile
                os.system('aws configure --profile %s' % (dasid_answer))

                mfa_serial = subprocess.getoutput("aws configure get %s.mfa_serial" % (dasid_answer))
                if not mfa_serial or mfa_serial == "":
                    mfa_serial = input('Provide the ARN of your MFA device (soft token) or the ID of your (hardware token): ')
                    if mfa_serial is None:
                        logger.error("MFA serial cannot be empty. Aborting installation")
                        sys.exit(255)
                    else:
                        mfa_serial_configured = mfa_serial

                mfa_serial_configured = mfa_serial
                # configure user profile
                os.system('aws configure set mfa_serial %s --profile %s' % (mfa_serial, dasid_answer))

                configured = True

                # Change AWS files owner for Linux
                if (platform.system() == "Linux"):
                    os.system('chown -R "%s:%s" %s' % (gcredsUser, gcredsUser, userPath))
        else:
            print("\nChecking current configuration for %s:" % dasid_answer)

            mfa_serial_configured = subprocess.getoutput("aws configure get %s.mfa_serial" % (dasid_answer))
            print(" - Is mfa_serial configured ?", mfa_serial_configured if mfa_serial_configured else "NO")

            aws_secret_access_key_configured = subprocess.getoutput("aws configure get %s.aws_secret_access_key" % dasid_answer)
            print(" - Is aws_secret_access_key configured ?", aws_secret_access_key_configured if aws_secret_access_key_configured else "NO")

            aws_access_key_id_configured = subprocess.getoutput("aws configure get %s.aws_access_key_id" % dasid_answer)
            print(" - Is aws_access_key_id configured ?", aws_access_key_id_configured if aws_access_key_id_configured else "NO")

            if mfa_serial_configured and aws_secret_access_key_configured and aws_access_key_id_configured:
               configured = True
            else :
                not_well_configured = True

    creds_response = None
    while not creds_response:
        try:
            # Get a token code from user
            tokencode_answer = input('Provide a MFA token code: ')

            sts_session = boto3.Session(profile_name=dasid_answer)
            sts_client = sts_session.client('sts')
            creds_response = sts_client.assume_role(
                            DurationSeconds=900,
                            RoleArn='arn:aws:iam::935229214006:role/UR-AtosReadOnly',
                            RoleSessionName='gcreds-installer',
                            SerialNumber=mfa_serial_configured,
                            TokenCode=tokencode_answer
                        )
        except ClientError as ce:
            error_message = "%s : %s" % (ce.response['Error']['Code'], ce.response['Error']['Message'])
            logger.error(error_message)
            continue
        except ParamValidationError as pve:
            logger.error(pve.kwargs['report'])
            pass

    accounts = get_profile_account_list(creds_response)

    config_file = open("%s/%s" % (userPath, AWS_CONFIG_FILE), 'r+')
    config_file_content = config_file.read()

    for account in accounts:
        if account['Account Name']['S'] not in config_file_content:
            config_file.write("\n[profile %s]" % account['Account Name']['S'])
            config_file.write("\nrole_arn = arn:aws:iam::%s:role/UR-AtosAdmin" % account['Account ID']['S'])
            config_file.write("\nsource_profile = %s\n" % dasid_answer)
        else:
            if not subprocess.getoutput("aws configure get %s.role_arn" % (account['Account Name']['S'])):
                os.system('aws configure set role_arn arn:aws:iam::%s:role/UR-AtosAdmin --profile %s' % (account['Account ID']['S'], account['Account Name']['S']))
            if not subprocess.getoutput("aws configure get %s.source_profile" % (account['Account Name']['S'])):
                os.system('aws configure set source_profile %s --profile %s' % (dasid_answer, account['Account Name']['S']))

    config_file.close()

    code_path = ""
    if(args.source):
        print("Using Gcreds source %s." % args.source)
        code_path = args.source
    elif args.zip_file:
        print("Using Gcreds zip file %s." % args.zip_file)
        code_path = args.zip_file
    else:
        print("Using Gcreds S3")
        try:
            code_path = get_gcreds_from_s3(creds_response)
        except ClientError as ce:
            if ce.response['Error']['Code'] == '404':
                error_message = "Gcreds S3 : %s : %s" % (ce.response['Error']['Code'], ce.response['Error']['Message'])
                logger.error(error_message)
                sys.exit(255)
            else:
                error_message = "%s : %s" % (ce.response['Error']['Code'], ce.response['Error']['Message'])
                logger.error(error_message)
            pass

    if (platform.system() == "Linux" or platform.system() == "Darwin") or "CYGWIN" in platform.system():
        if args.update:
            # Installing gcreds
            update_gcreds_on_linux_like_os(code_path)
        else:
            # Installing gcreds
            install_gcreds_on_linux_like_os(code_path)
    else:
        logger.error("gcreds-install not yet implemented for %s." % platform.system())
        sys.exit(255)


@arghandler.subcmd('DevOps', help='Install gcreds for atos-evanios MID servers')
def devOps(parser, context, args):
    print("**Installing gcreds for DevOps servers**")
    parser.add_argument('-u','--user',required=True)
    parser.add_argument('-z','--zip-file',required=False)
    parser.add_argument('-s','--source',required=False)
    parser.add_argument('-U','--update',required=False,action="store_true")
    args = parser.parse_args(args)

    # S3 ?
    if args.zip_file:
        print("Using Gcreds zip file %s." % args.zip_file)
        code_path = args.zip_file
    elif args.source:
        print("Using Gcreds source %s." % args.source)
        code_path = args.source
    else:
        print("Using Gcreds S3")
        try:
            code_path = get_gcreds_from_s3()

        except ClientError as ce:
            if ce.response['Error']['Code'] == '404':
                error_message = "Gcreds S3 : %s : %s" % (ce.response['Error']['Code'], ce.response['Error']['Message'])
                logger.error(error_message)
                sys.exit(255)
            else:
                error_message = "%s : %s" % (ce.response['Error']['Code'], ce.response['Error']['Message'])
                logger.error(error_message)

    if args.update:
        # Installing gcreds
        update_gcreds_on_linux_like_os(code_path)
    else:
        # Installing gcreds
        install_gcreds_on_linux_like_os(code_path)

    userPath = "/home/%s" % args.user
    gcredsUser = args.user
    gcredsUserGroup = args.user
    createAWSConfigurationFiles(userPath, gcredsUser, gcredsUserGroup)

    print("**Installation done for gcreds for DevOps servers**")

@arghandler.subcmd('AtosEvanios', help='Install gcreds for atos-evanios MID servers')
def atosEvanios(parser, context, args):
    print("**Installing gcreds for AtosEvanios MID servers**")
    parser.add_argument('-z','--zip-file',required=False)
    parser.add_argument('-s','--source',required=False)
    parser.add_argument('-U','--update',required=False,action="store_true")
    args = parser.parse_args(args)

    instanceInfo = loadEC2InstanceInformation()
    accountId = instanceInfo["accountId"]

    # S3 ?
    if args.zip_file:
        print("Using Gcreds zip file %s." % args.zip_file)
        code_path = args.zip_file
    elif args.source:
        print("Using Gcreds source %s." % args.source)
        code_path = args.source
    else:
        print("Using Gcreds S3")
        try:
            code_path = get_gcreds_from_s3()

        except ClientError as ce:
            if ce.response['Error']['Code'] == '404':
                error_message = "Gcreds S3 : %s : %s" % (ce.response['Error']['Code'], ce.response['Error']['Message'])
                logger.error(error_message)
                sys.exit(255)
            else:
                error_message = "%s : %s" % (ce.response['Error']['Code'], ce.response['Error']['Message'])
                logger.error(error_message)
                sys.exit(255)

    if args.update:
        # Installing gcreds
        update_gcreds_on_linux_like_os(code_path)
    else:
        # Installing gcreds
        install_gcreds_on_linux_like_os(code_path)

    gcredsEnv = {"102512488663" : "addev",
                "935229214006" : "adqa",
                "872277419998" : "ad1" }

    if accountId not in gcredsEnv:
        logger.error("ERROR: AWS Account ID %s not recognized\n       Please check your environment" % accountId)
        sys.exit(255)

    gcredsUser = "snowmidsvc@%s.mpcaws.idm.atos.net" % gcredsEnv[accountId]
    gcredsUserGroup = "domain users@%s.mpcaws.idm.atos.net" % gcredsEnv[accountId]
    userPath = "/home/%s" % gcredsUser

    createAWSConfigurationFiles(userPath, gcredsUser, gcredsUserGroup)

    os.system('(crontab -l; echo -e "\n*/45 * * * * /usr/local/bin/gcreds -M AtosEvanios >>/opt/gcreds/logs/gcron.log 2>&1") | crontab')

    # Run gcreds one time to generate first credentials
    os.system("/usr/local/bin/gcreds -M AtosEvanios")

    print("**Installation done for gcreds for atos-evanios MID servers**")

def checkEnvironment():

    # Is awscli installed ?
    if distutils.spawn.find_executable('aws') is None:
        pip.main(['install', 'awscli'])

    # Are mandatory executable installed ?
    for prog in ['jq', 'date', 'hostname', 'awk', 'grep', 'cat']:
        if distutils.spawn.find_executable(prog) is None:
            if distutils.spawn.find_executable("apt") is not None:
                os.system("apt install %s -y" % prog)
            elif distutils.spawn.find_executable("yum") is not None:
                os.system("yum install %s -y" % prog)
            else:
                logger.error("ERROR: %s was not found and can't be install. Did not find package manager (yum or apt)" % prog)
                sys.exit(255)

def main():
    checkEnvironment()

    handler = arghandler.ArgumentHandler(use_subcommand_help=True,enable_autocompletion=True)
    handler.run(sys.argv[1:])

if __name__ == '__main__':
    sys.exit(main())
