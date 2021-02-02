#!/usr/bin/env python3
"""
Summary:
    buildrpm (python3):  gcreds binary operating system package (.rpm, Redhat, Redhat-based systems)

        - Automatic determination of version to be built
        - Build version can optionally be forced to a specific version
        - Resulting rpm ackage produced in packaging/rpm directory
        - To execute build, from the directory of this module, run:

    .. code-block:: python

        $ cd ../<project dir>
        $ make buildrpm

Author:
    Blake Huber
    Copyright 2017-2021, All Rights Reserved.

License:
    General Public License v3
    Additional terms may be found in the complete license agreement:
    https://github.com/fstab50/gcreds

OS Support:
    - Redhat, CentOS, Fedora, Redhat-based variants

Dependencies:
    - Requires python3, developed and tested under python3.6
"""
import argparse
import inspect
import json
import os
import sys
import subprocess
import tarfile
import fileinput
from shutil import copy2 as copyfile
from shutil import rmtree, which
import docker
import distro
import loggers
from pyaws.utils import stdout_message, export_json_object
from pyaws.colors import Colors
from common import debug_header

try:
    from pyaws.core.oscodes_unix import exit_codes
except Exception:
    from pyaws.core.oscodes_win import exit_codes    # non-specific os-safe codes


# globals
PROJECT = 'gcreds'
module = os.path.basename(__file__)
TMPDIR = '/tmp/build'
VOLMNT = '/tmp/rpm'
CONTAINER_VOLMNT = '/mnt/rpm'
PACKAGE_CONFIG = '.rpm.json'
DISTRO_LIST = ['centos7', 'amazonlinux', 'redhat7']

# docker
dclient = docker.from_env()

# formatting
act = Colors.ORANGE                     # accent highlight (bright orange)
bd = Colors.BOLD + Colors.WHITE         # title formatting
bn = Colors.CYAN                        # color for main binary highlighting
lk = Colors.DARK_BLUE                    # color for filesystem path confirmations
red = Colors.RED                        # color for failed operations
yl = Colors.GOLD3                       # color when copying, creating paths
rst = Colors.RESET                      # reset all color, formatting


# global logger
logger = loggers.getLogger('1.0')


def git_root():
    """
    Summary.

        Returns root directory of git repository

    """
    cmd = 'git rev-parse --show-toplevel 2>/dev/null'
    return subprocess.getoutput(cmd).strip()


def help_menu():
    """
    Displays command line parameter options
    """
    menu = '''
                          ''' + bd + module + rst + ''' help contents

  ''' + bd + '''DESCRIPTION''' + rst + '''

          Builds an installable package (.rpm) for Redhat, CentOS, and Fedora
          variants of the Linux Operatining System

  ''' + bd + '''OPTIONS''' + rst + '''

            $ python3  ''' + act + module + rst + '''  --build  [ --force-version <VERSION> ]

                         -b, --build
                         -d, --distro <value>
                        [-D, --debug  ]
                        [-f, --force  ]
                        [-h, --help   ]
                        [-s, --set-version  <value> ]

        ''' + bd + '''-b''' + rst + ''', ''' + bd + '''--build''' + rst + ''':  Build Operating System package (.deb, Debian systems)
            When given without the --set-version parameter switch, build ver-
            sion is extracted from the project repository information

        ''' + bd + '''-d''' + rst + ''', ''' + bd + '''--distro''' + rst + ''':  Specifies the Docker Operating System Image to use when
            building.  Allowable Values:

                    -   centos7 (DEFAULT)
                    -   amazonlinux
                    -   redhat7

        ''' + bd + '''-F''' + rst + ''', ''' + bd + '''--force''' + rst + ''':  When given, overwrites any pre-existing build artifacts.
            DEFAULT: False

        ''' + bd + '''-s''' + rst + ''', ''' + bd + '''--set-version''' + rst + '''  (string):  When given, overrides all version infor-
            mation contained in the project to build the exact version speci-
            fied by VERSION parameter

        ''' + bd + '''-d''' + rst + ''', ''' + bd + '''--debug''' + rst + ''': Debug mode, verbose output.

        ''' + bd + '''-h''' + rst + ''', ''' + bd + '''--help''' + rst + ''': Print this help menu
    '''
    print(menu)
    return True


def clean(directory):
    # rm residual installation files from build directory
    bytecode_list = list(
                        filter(
                            lambda x: x.endswith('.pyc') or x.endswith('.pyo'), os.listdir(directory)
                        )
                    )
    for artifact in bytecode_list:
        os.remove(directory + '/' + artifact)
        logger.info('Artifact {} cleaned from {}'.format(artifact, directory))
    return True


def current_branch(path):
    """
    Returns:
        git repository source url, TYPE: str
    """
    cmd = 'git branch'
    pwd = os.getcwd()
    os.chdir(path)

    try:
        if '.git' in os.listdir('.'):

            branch = subprocess.getoutput('git branch').split('*')[1].split('\n')[0][1:]

        else:
            ex = Exception(
                '%s: Unable to identify current branch - path not a git repository: %s' %
                (inspect.stack()[0][3], path))
            raise ex

        os.chdir(pwd)      # return cursor

    except IndexError:
        logger.exception(
                '%s: problem retrieving git branch for %s' %
                (inspect.stack()[0][3], path)
            )
        return ''
    return branch


def read(fname):
    basedir = os.path.dirname(sys.argv[0])
    return open(os.path.join(basedir, fname)).read()


def masterbranch_version():
    """
    Returns version denoted in the master branch of the repository
    """

    branch = current_branch(git_root())
    cmds = ['git checkout master', 'git checkout {}'.format(branch)]

    try:
        # checkout master
        stdout_message('Checkout master branch:\n\n%s' % subprocess.getoutput(cmds[0]))
        masterversion = read(SCRIPT_DIR + '/version.py').split('=')[1].strip().strip('"')

        # return to working branch
        stdout_message(
            'Returning to working branch: checkout %s\n\n%s' %
            (branch, subprocess.getoutput(cmds[1]))
            )
    except Exception:
        return None
    return masterversion


def current_version(binary):
    """
    Summary:
        Returns current binary package version if locally
        installed, master branch __version__ if the binary
        being built is not installed locally
    Args:
        :root (str): path to the project root directory
        :binary (str): Name of main project exectuable
    Returns:
        current version number of the project, TYPE: str
    """

    if which(binary):

        os_type = distro.linux_distribution()[0]

        if os_type == 'Redhat' and which('yum'):
            cmd = 'yum info ' + binary + ' 2>/dev/null | grep Version'

        elif os_type == 'Redhat' and which('rpm'):
            cmd = 'rpm -qi ' + binary + ' 2>/dev/null | grep Version'

        elif os_type == 'Ubuntu' and which('apt'):
            cmd = 'apt show ' + binary + ' 2>/dev/null | grep Version | head -n1'

        try:

            installed_version = subprocess.getoutput(cmd).split(':')[1].strip()
            return greater_version(installed_version, __version__)

        except Exception:
            logger.info(
                '%s: Build binary %s not installed, comparing current branch version to master branch version' %
                (inspect.stack()[0][3], binary))
    return greater_version(masterbranch_version(), __version__)


def greater_version(versionA, versionB):
    """
    Summary:
        Compares to version strings with multiple digits and returns greater
    Returns:
        greater, TYPE: str
    """
    try:

        list_a = versionA.split('.')
        list_b = versionB.split('.')

    except AttributeError:
        return versionA or versionB    # either A or B is None

    try:

        for index, digit in enumerate(list_a):
            if int(digit) > int(list_b[index]):
                return versionA
            elif int(digit) < int(list_b[index]):
                return versionB
            elif int(digit) == int(list_b[index]):
                continue

    except ValueError:
        return versionA or versionB    # either A or B is ''
    return versionA


def increment_version(current):
    """
    Returns current version incremented by 1 minor version number
    """
    minor = current.split('.')[-1]
    major = '.'.join(current.split('.')[:-1])
    inc_minor = int(minor) + 1
    return major + '.' + str(inc_minor)


def tar_archive(archive, source_dir):
    """
    Summary:
        - Creates .tar.gz compressed archive
        - Checks that file was created before exit
    Returns:
        Success | Failure, TYPE: bool
    """
    try:
        # rm any python byte-code artifacts
        clean(source_dir)

        with tarfile.open(archive, "w:gz") as tar:
            tar.add(source_dir, arcname=os.path.basename(source_dir))

        if os.path.exists(archive):
            return True

    except OSError:
        logger.exception(
            '{}: Unable to create tar archive {}'.format(inspect.stack()[0][3], archive))
    except Exception as e:
        logger.exception(
            '%s: Unknown problem while creating tar archive %s:\n%s' %
            (inspect.stack()[0][3], archive, str(e)))
    return False


def builddir_structure(param_dict, force, debug):
    """
    Summary.

        - Updates path in binary exectuable
        - Updates

    Args:
        :root (str): full path to root directory of the git project
        :builddir (str): name of current build directory which we need to populate

    Vars:
        :lib_path (str): src path to library modules in project root
        :builddir_path (str): dst path to root of the current build directory
         (/<path>/gcreds-1.X.X dir)

    Returns:
        Success | Failure, TYPE: bool

    """
    root = git_root()
    build_root = TMPDIR
    project_dirname = root.split('/')[-1]
    arrow = yl + Colors.BOLD + '-->' + rst

    # files
    specfile = param_dict['SpecFile']['Name']
    compfile = param_dict['BashCompletion']
    repofile = param_dict.get('RepoDefinitionFile')
    builddir = param_dict['SpecFile']['BuildDirName']
    buildscript = param_dict['DockerBuildScript']

    # full paths
    rpm_src = root + '/packaging/rpm'
    builddir_path = build_root + '/' + builddir
    lib_path = root + '/' + 'core'

    try:

        stdout_message(f'Assembling build directory artifacts in {bn + builddir + rst}')

        # create build directory
        if os.path.exists(builddir_path):
            rmtree(builddir_path)
        os.makedirs(builddir_path)
        stdout_message(
            message='Created:\t{}'.format(yl + builddir_path + rst),
            prefix='OK')

        # place main bin to builddir
        if not os.path.exists(builddir_path + '/' + PROJECT_BIN):
            binary_src = root + '/' + PROJECT_BIN
            binary_dst = builddir_path + '/' + PROJECT_BIN
            copyfile(binary_src, binary_dst)
            stdout_message(
                message='Copied:  {} {} {}'.format(lk + binary_src + rst, arrow, lk + binary_dst + rst),
                prefix='OK')

        # place library dependencies
        for libfile in os.listdir(lib_path):
            if not (libfile.endswith('.pyc') or libfile.endswith('.pyo')):
                lib_src = lib_path + '/' + libfile
                lib_dst = builddir_path + '/' + libfile
                copyfile(lib_src, lib_dst)

                # status msg
                lib_src = '../' + project_dirname + (lib_src)[len(root):]
                stdout_message(
                    message='Copied:  {} {} {}'.format(lk + lib_src + rst, arrow, lk + lib_dst + rst),
                    prefix='OK')

        # place specfile in build_root
        spec_dst = build_root + '/' + specfile
        if os.path.exists(spec_dst):
            os.remove(spec_dst)
        copyfile(rpm_src + '/' + specfile, spec_dst)

        # verify build spec placement
        if os.path.exists(spec_dst):
            stdout_message(
                message='Copied:  {} {} {}'.format(
                    lk + rpm_src + '/' + specfile + rst, arrow, lk + spec_dst + rst),
                prefix='OK')

        # place bash completion artifacts
        comp_src = root + '/' + 'bash' + '/' + compfile
        comp_dst = builddir_path + '/' + compfile

        if os.path.exists(comp_src):
            if os.path.exists(comp_dst):
                os.remove(comp_dst)
            copyfile(comp_src, comp_dst)

        # verify build spec placement
        if os.path.exists(comp_dst):
            # status msg
            comp_src = '../' + project_dirname + (comp_src)[len(root):]
            stdout_message(
                message='Copied:  {} {} {}'.format(
                    lk + comp_src + '/' + compfile + rst, arrow, lk + comp_dst + '/' + compfile + rst),
                prefix='OK')

        # build script placement
        _src = rpm_src + '/' + buildscript
        _dst = build_root + '/' + buildscript
        install_builddir_artifact(root, _src, _dst, debug)

        # place bash completion artifacts
        if repofile:
            _src = rpm_src + '/' + repofile
            _dst = builddir_path + '/' + repofile
            install_builddir_artifact(root, _src, _dst, debug)
        else:
            stdout_message(
                    message='repository definition file not defined - skip',
                    prefix='INFO'
                )

    except OSError as e:
        logger.exception(
            '{}: Problem creating dirs on local fs'.format(inspect.stack()[0][3]))
        return False
    return True


def build_package(build_root, builddir):
    """
    Summary.

        Creates actual .deb package for current build, build version

    Returns:
        Success | Failure, TYPE: bool

    """
    try:

        pwd = os.getcwd()

        if os.path.exists(builddir):
            os.chdir(builddir)
            cmd = 'rpmbuild -ba SPECS/gcreds.spec'
            stdout_message('Building {}...  '.format(bn + builddir + rst))
            stdout_message(subprocess.getoutput(cmd))
            os.chdir(pwd)

        else:
            logger.warning(
                'Build directory {} not found. Failed to create .deb package'.format(builddir))
            os.chdir(pwd)
            return False

    except OSError as e:
        logger.exception(
            '{}: Error during os package creation: {}'.format(inspect.stack()[0][3], e))
        return False
    except Exception as e:
        logger.exception(
            '{}: Unknown Error during os package creation: {}'.format(inspect.stack()[0][3], e))
        return False
    return True


def builddir_content_updates(param_dict, osimage, version):
    """
    Summary:
        Updates builddir contents:
        - main exectuable has path to libraries updated
        - builddir DEBIAN/control file version is updated to current
        - updates the version.py file if version != to __version__
          contained in the file.  This oaccurs if user invokes the -S /
          --set-version option
    Args:
        :root (str): project root full fs path
        :builddir (str): dirname of the current build directory
        :binary (str): name of the main exectuable
        :version (str): version label provided with --set-version parameter. None otherwise
    Returns:
        Success | Failure, TYPE: bool
    """
    root = git_root()
    build_root = TMPDIR
    rpm_src = root + '/packaging/rpm'
    project_dirname = root.split('/')[-1]
    major = '.'.join(version.split('.')[:2])
    minor = version.split('.')[-1]

    # files
    specfile = param_dict['SpecFile']['Name']
    builddir = param_dict['SpecFile']['BuildDirName']
    version_module = param_dict['VersionModule']
    dockeruser = param_dict['DockerUser']

    # full paths
    spec_path = rpm_src + '/' + specfile
    builddir_path = build_root + '/' + builddir
    binary_path = builddir_path + '/' + PROJECT_BIN
    lib_src = root + '/' + 'core'

    # dependencies
    deplist = None
    for dep in param_dict['Dependencies']:
        if deplist is None:
            deplist = str(dep)
        else:
            deplist = deplist + ', ' + str(dep)

    try:

        stdout_message(
                'Generating build spec file and build artifacts in %s' %
                yl + builddir_path + rst
            )

        # main exec bin
        with open(binary_path) as f1:
            f2 = f1.readlines()

            for index, line in enumerate(f2):
                if line.startswith('pkg_lib='):
                    newline = 'pkg_lib=' + '\"' + '/usr/local/lib/' + PROJECT + '\"\n'
                    f2[index] = newline

                elif line.startswith('LOG_DIR='):
                    logline = 'LOG_DIR=' + '\"' + '/var/log' + '\"\n'
                    f2[index] = logline
            f1.close()

        # rewrite bin
        with open(binary_path, 'w') as f3:
            f3.writelines(f2)
            path = binary_path
            stdout_message('Bin {} successfully updated.'.format(yl + path + rst))

        # rewrite version file with current build ver
        with open(builddir_path + '/' + version_module, 'w') as f4:
            f3 = ['__version__=\"' + version + '\"\n']
            f4.writelines(f3)
            path = builddir_path + '/' + version_module
            stdout_message('Module {} successfully updated.'.format(yl + path + rst))

        # rewrite git project version file with current build version in case delta
        with open(lib_src + '/' + version_module, 'w') as f5:
            f4 = ['__version__=\"' + version + '\"\n']
            f5.writelines(f4)
            path = '../' + project_dirname + (lib_src + '/' + version_module)[len(root):]
            stdout_message('Module {} successfully updated.'.format(yl + path + rst))

        if os.path.exists(build_root + '/' + specfile):
            # update specfile - major version
            for line in fileinput.input([build_root + '/' + specfile], inplace=True):
                print(line.replace('MAJOR_VERSION', major), end='')
            stdout_message(f'Updated {specfile} with MAJOR_VERSION', prefix='OK')

            # update specfile - minor version
            for line in fileinput.input([build_root + '/' + specfile], inplace=True):
                print(line.replace('MINOR_VERSION', minor), end='')
            stdout_message(f'Updated {specfile} with MINOR_VERSION', prefix='OK')

            # update specfile - DOCKERUSER
            for line in fileinput.input([build_root + '/' + specfile], inplace=True):
                print(line.replace('DOCKERUSER', dockeruser), end='')
            stdout_message(f'Updated {specfile} with DOCKERUSER ({dockeruser})', prefix='OK')

            # update specfile - Dependencies
            for line in fileinput.input([build_root + '/' + specfile], inplace=True):
                print(line.replace('DEPLIST', deplist), end='')
            stdout_message(f'Updated {specfile} with Dependencies ({deplist})', prefix='OK')

        else:
            stdout_message(
                message=f'{specfile} not found in build directory. Cannot update... halting build.',
                prefix='WARN')
            sys.exit(1)

        # rm residual installation files from build directory
        clean(builddir_path)

    except OSError as e:
        logger.exception(
            '%s: Problem while updating builddir contents: %s' %
            (inspect.stack()[0][3], str(e)))
        return False
    return True


def cp_dockerfiles(src, dst):
    """
    Copy dockerfiles and associated build artifacts to build_root
    """
    # place docker build script
    script_src = rpm_src + '/' + dockerscript
    script_dst = build_root + '/' + dockerscript

    build_list = os.listdir(src)
    for file in build_list:
        copyfile(file, dst + '/' + file)

    # cp Dockerfile to build root
    copyfile(
            docker_path + '/' + 'Dockerfile',
            builddir_path + '/' + 'Dockerfile'
        )

    # verify build spec placement
    stdout_message(
        message='Copied: {} {} {}'.format(
            lk + script_src + rst, arrow, lk + script_dst + rst),
        prefix='OK')
    return build_list


def container_running(cid, debug=False):
    """
    Summary:
        Verifies if a container is activly running
    Args:
        :cid (str): Container name or hex identifier
        :dclient (object): global docker client
    Returns:
        True (running) | False (stopped)
        TYPE: bool
    """

    success_msg = f'Container {cid} running'

    try:
        container = dclient.containers.get(cid)

        if container.status == 'running':
            if debug:
                stdout_message(success_msg, prefix='OK')
            return True
    except Exception:
        if cid in subprocess.getoutput('docker ps'):
            stdout_message(success_msg, prefix='OK')
            return True
        else:
            stdout_message(f'Container {cid} stopped', prefix='WARN')
    return False


def display_package_contents(rpm_path, contents):
    """
    Summary:
        Output newly built package contents.
    Args:
        :build_root (str):  location of newly built rpm package
        :version (str):  current version string, format:  '{major}.{minor}.{patch num}'
    Returns:
        Success | Failure, TYPE: bool
    """
    tab = '\t'.expandtabs(2)
    tab4 = '\t'.expandtabs(4)
    width = 90
    package = os.path.split(rpm_path)[1]
    path, discard = os.path.split(contents)
    pwd = os.getcwd()
    os.chdir('.') if not path else os.chdir(path)

    with open(contents) as f1:
        unformatted = f1.readlines()

    # title header and subheader
    header = '\n\t\tPackage Contents:  ' + bd + package + rst + '\n'
    print(header)
    subheader = tab + 'Permission' + tab + ' Owner/Group' + '\t' + 'ctime' \
        + '\t'.expandtabs(8) + 'File'
    print(subheader)

    # divider line
    list(filter(lambda x: print('-', end=''), range(0, width + 1))), print('\r')

    # content
    for line in unformatted:
        permissions = [tab + line.split()[0]]
        raw = tab4 + 'root root'
        ctime = line.split()[5:8]
        f_ctime = tab4 + ''.join([x + ' ' for x in ctime])
        content_path = tab4 + yl + line.split()[-1] + rst
        fline = permissions[0] + raw + f_ctime + content_path
        print(fline)
    print('\n')
    os.chdir(pwd)
    return True


def docker_daemon_up():
    """
    Summary:
        Determines if docker installed and running by
        evaluating the exit code of docker images cmd
    Returns:
        True (running) | False, TYPE: bool
    """
    cmd = 'docker images >/dev/null 2>&1; echo $?'
    if which('docker') and int(subprocess.getoutput(cmd)) == 0:
        return True
    else:
        stdout_message('Docker engine not running or not accessible', prefix='WARN')
    return False


def docker_init(src, builddir, osimage, debug):
    """
    Summary:
        Creates docker image and container
    Args:
    Returns:
        Container id (Name) | Failure (None)
    """
    iname = 'rpmbuild'                     # image name
    cname = iname + 'A'                    # container id
    host_mnt = VOLMNT                      # host volume mount point
    container_mnt = CONTAINER_VOLMNT       # container volume internal mnt pt
    docker_user = 'builder'
    bash_cmd = '/bin/sleep 30'
    buildscript = 'docker-buildrpm.sh'

    try:

        # create host mount for container volume
        if not os.path.exists(host_mnt):
            os.makedirs(host_mnt)
            stdout_message(f'Created host mount {host_mnt} for container volume')

        # if image rpmbuild not exist, create
        try:

            image = dclient.images.get('centos7:%s' % iname)

            if image:
                stdout_message('Image already exists. Creating Container...')

        except Exception:
            # create new docker image
            os.chdir(src)
            cmd = 'docker build -t centos7:rpmbuild .'
            subprocess.call([cmd], shell=True, cwd=src)
            stdout_message('Built image', prefix='OK')

        # start container detached
        container = dclient.containers.run(
                name=cname,
                image=osimage + ':' + iname,
                command=bash_cmd,
                volumes={host_mnt: {'bind': container_mnt, 'mode': 'rw'}},
                user=docker_user,
                security_opt=['label:disable'],
                detach=True
            )

        # verify container is running
        if not container_running(cname):
            stdout_message(f'Container {cname} not started - abort', prefix='WARN')
            return False

        # copy build files to container
        stdout_message('Begin cp files into container')

        # copy files from temporary build directory to container
        os.chdir(builddir)

        buildfile_list = list(
            filter(
                lambda x: x.endswith('.tar.gz') or x.endswith('.spec') or x.endswith('.sh'), os.listdir('.')
            )
        )
        buildfile_list.append(buildscript)

        if debug:
            print(f'buildfile_list contains:\n\n\t%s' % export_json_object(buildfile_list))
            print(f'osimage is: {osimage}')
            print(f'iname is: {iname}')
            print(f'container name is: {container.name}')

        for file in buildfile_list:
            # local fs >> container:/home/builder
            cmd = f'docker cp {file} {container.name}:/home/builder/{file}'
            # status
            if not subprocess.getoutput(cmd):
                stdout_message(f'{file} copied to container {container.name} successfully')
            else:
                stdout_message(
                        f'Problem copying {file} to container {container.name}',
                        prefix='WARN'
                    )

        # exec rpmbuild script
        cmd = f'docker exec -i {container.name} sh -c \'cd ~ && bash {buildscript}\''
        stdout_message(subprocess.getoutput(cmd))

        if container_running(container.name):
            return container
    except OSError as e:
        logger.exception(
            '%s: Problem while updating builddir contents: %s' %
            (inspect.stack()[0][3], str(e)))
    return None


def install_builddir_artifact(root, source, destination, debug):
    """
    Summary.

        Installs any file object into the current build package

    Args:
        :root (str): build root directory
        :source (str): complete path to source file; inclusive
        :destination (str): complete path to destination file; inclusive

    Returns:

    """
    project_dirname = root.split('/')[-1]
    arrow = yl + Colors.BOLD + '-->' + rst
    src_file = os.path.split(source)[1]

    if debug:
        stdout_message(f'Source path is: {source}')
        stdout_message(f'Destination path is: {destination}')

    if os.path.exists(source):
        if os.path.exists(destination):
            os.remove(destination)
        copyfile(source, destination)
    else:
        stdout_message(
                message='repository definition file source not found to include in build package',
                prefix='WARN'
            )

    # verify build spec placement
    if os.path.exists(destination):
        # status msg
        source_path = '../' + project_dirname + (source)[len(root):]
        stdout_message(
            message='Copied:  {} {} {}'.format(
                lk + source_path + '/' + src_file + rst, arrow, lk + destination + rst),
            prefix='OK')
    return True


def main(setVersion, environment, force=False, debug=False):
    """
    Summary:
        Create build directories, populate contents, update contents
    Args:
        :version (str): version number of rpm created
        :data (dict): build parameters for rpm build process
        :force (bool): If True, overwrites any pre-existing build artifacts
    Returns:
        Success | Failure, TYPE: bool
    """
    # all globals declared here
    global PROJECT_BIN
    PROJECT_BIN = 'gcreds'
    global PROJECT_ROOT
    PROJECT_ROOT = git_root()
    global SCRIPT_DIR
    SCRIPT_DIR = PROJECT_ROOT + '/' + 'scripts'
    global BUILD_ROOT
    BUILD_ROOT = TMPDIR
    global RPM_SRC
    RPM_SRC = PROJECT_ROOT + '/packaging/rpm'
    global CURRENT_VERSION
    CURRENT_VERSION = current_version(PROJECT_BIN)

    # sort out version numbers, forceVersion is overwrite of pre-existing build artifacts
    global VERSION
    if setVersion:
        VERSION = setVersion
    elif CURRENT_VERSION:
        VERSION = increment_version(CURRENT_VERSION)
    else:
        stdout_message('Could not determine current {} version'.format(bd + PROJECT + rst))
        sys.exit(exit_codes['E_DEPENDENCY']['Code'])

    # log
    stdout_message(f'Current version of last build: {bd + CURRENT_VERSION + rst}')
    stdout_message(f'Version to be used for this build: {act + VERSION + rst}')

    # create initial binary working dir
    BUILDDIRNAME = PROJECT + '-' + '.'.join(VERSION.split('.')[:2])

    # sub in current values
    parameter_obj = ParameterSet(PROJECT_ROOT + '/' + PACKAGE_CONFIG, VERSION)
    vars = parameter_obj.create()

    VERSION_FILE = vars['VersionModule']

    if debug:
        export_json_object(vars)

    r_struture = builddir_structure(vars, VERSION, debug)
    r_updates = builddir_content_updates(vars, environment, VERSION)

    # create tar archive
    target_archive = BUILD_ROOT + '/' + PROJECT_BIN + '-' + VERSION + '.tar.gz'
    source_dir = BUILD_ROOT + '/' + BUILDDIRNAME
    r_tarfile = tar_archive(target_archive, source_dir)

    # launch docker container and execute final build steps
    if r_struture and r_updates and r_tarfile:
        # status
        msg = yl + BUILD_ROOT + '/' + target_archive + rst
        stdout_message('tgz archive built: %s' % msg)

        # trigger docker build based on environment:
        container = docker_init(
                PROJECT_ROOT + '/packaging/docker/' + environment,
                BUILD_ROOT,
                environment,
                debug
            )
        if container:
            return postbuild(PROJECT_ROOT, container, RPM_SRC, SCRIPT_DIR, VERSION_FILE, VERSION)
    return False


def options(parser, help_menu=False):
    """
    Summary:
        parse cli parameter options
    Returns:
        TYPE: argparse object, parser argument set
    """
    parser.add_argument("-b", "--build", dest='build', default=False, action='store_true', required=False)
    parser.add_argument("-D", "--debug", dest='debug', default=False, action='store_true', required=False)
    parser.add_argument("-d", "--distro", dest='distro', default='centos7', nargs='?', type=str, required=False)
    parser.add_argument("-F", "--force", dest='force', default=False, action='store_true', required=False)
    parser.add_argument("-s", "--set-version", dest='set', default=None, nargs='?', type=str, required=False)
    parser.add_argument("-h", "--help", dest='help', default=False, action='store_true', required=False)
    return parser.parse_args()


def is_installed(binary):
    """
    Verifies if program installed on Redhat-based Linux system
    """
    cmd = 'rpm -qa | grep ' + binary
    return True if subprocess.getoutput(cmd) else False


def ospackages(pkg_list):
    """Summary
        Install OS Package Prerequisites
    Returns:
        Success | Failure, TYPE: bool
    """
    try:
        for pkg in pkg_list:

            if is_installed(pkg):
                logger.info(f'{pkg} binary is already installed - skip')
                continue

            elif which('yum'):
                cmd = 'sudo yum install ' + pkg + ' 2>/dev/null'
                print(subprocess.getoutput(cmd))

            elif which('dnf'):
                cmd = 'sudo dnf install ' + pkg + ' 2>/dev/null'
                print(subprocess.getoutput(cmd))

            else:
                logger.warning(
                    '%s: Dependent OS binaries not installed - package manager not identified' %
                    inspect.stack()[0][3])

    except OSError as e:
        logger.exception('{}: Problem installing os package {}'.format(inspect.stack()[0][3], pkg))
        return False
    return True


def prebuild(builddir, volmnt, parameter_file):
    """Summary:
        Prerequisites and dependencies for build execution
    Returns:
        Success | Failure, TYPE: bool
    """
    def preclean(dir):
        """ Cleans residual build artifacts """
        try:
            if os.path.exists(dir):
                rmtree(dir)
        except OSError as e:
            logger.exception(
                '%s: Error while cleaning residual build artifacts: %s' %
                (inspect.stack()[0][3], str(e)))
            return False
        return True

    version_module = json.loads(read(parameter_file))['VersionModule']

    try:

        if preclean(builddir) and preclean(volmnt):
            stdout_message(f'Removed pre-existing build artifacts ({builddir}, {volmnt})')
        os.makedirs(builddir)
        os.makedirs(volmnt)

        root = git_root()
        src = root + '/core' + '/' + version_module
        dst = root + '/scripts' + '/' + version_module

        # deal with leftover build artifacts
        if os.path.exists(dst):
            os.remove(dst)
        r_cf = copyfile(src, dst)

        # import version module
        global __version__
        from version import __version__

        if r_cf and __version__ and docker_daemon_up():
            return True

    except Exception as e:
        logger.exception(
            '{}: Failure to import _version module _version'.format(inspect.stack()[0][3])
        )
    return False


def locate_artifact(filext, origin):
    """
    Summary.

        Finds rpm file object after creation
    Args:
        :filext (str): File extension searching for (".rpm")
        :origin (str): Starting directory for recursive search
    Returns:
        full path to rpm file | None if not found
    """
    for root, dirs, files in os.walk(origin):
        for file in files:
            if file.endswith(filext):
                return os.path.abspath(os.path.join(root, file))
    return None


def postbuild(root, container, rpm_root, scripts_dir, version_module, version):
    """
    Summary:
        Post-build clean up
    Args:
        :container (object): Docker container object
        :rpm_root (str):  target dir for rpm package files
        :script_dir (str): directory where scripts
        :version_module (str): name of module containing version number
        :version (str): current version label (Example: 1.6.8)
    Returns:
        Success | Failure, TYPE: bool
    """
    project_dirname = root.split('/')[-1]
    major = '.'.join(version.split('.')[:2])
    minor = version.split('.')[-1]
    volmnt = VOLMNT
    delete = True

    try:

        # cp rpm created to repo
        package = locate_artifact('.rpm', volmnt)
        if package:
            copyfile(locate_artifact('.rpm', volmnt), rpm_root)
            package_path = rpm_root + '/' + os.path.split(package)[1]

        # rpm contents text file
        contents = locate_artifact('.txt', volmnt)

        # stop and rm container
        cmd = f'docker stop {container.name}'
        subprocess.getoutput(cmd)

        # status
        if not container_running(container.name) and delete is True:
            stdout_message(f'{container.name} successfully halted', prefix='OK')
            cmd = f'docker rm {container.name}'
            subprocess.getoutput(cmd)

        # remove temp version module copied to scripts dir
        if os.path.exists(scripts_dir + '/' + version_module):
            os.remove(scripts_dir + '/' + version_module)

        # rewrite version file with 67rrent build version
        with open(root + '/core/' + version_module, 'w') as f3:
            f2 = ['__version__=\"' + version + '\"\n']
            f3.writelines(f2)
            path = project_dirname + (root + '/core/' + version_module)[len(root):]
            stdout_message(
                '{}: Module {} successfully updated.'.format(inspect.stack()[0][3], yl + path + rst)
                )

    except OSError as e:
        logger.exception('{}: Postbuild clean up failure'.format(inspect.stack()[0][3]))
        return ''
    return package_path, contents


class ParameterSet():
    """Recursion class for processing complex dictionary schema."""

    def __init__(self, parameter_file, version):
        """
        Summary.

            Retains major and minor version numbers + parameters
            in json form for later use

        Args:
            :parameter_file (str): path to json file obj containing
             parameter keys and values
            :version (str): current build version
        """
        self.parameter_dict = json.loads(read(parameter_file))
        self.version = version
        self.major = '.'.join(self.version.split('.')[:2])
        self.minor = self.version.split('.')[-1]

    def create(self, parameters=None):
        """
        Summary.

            Update parameter dict with current values appropriate
            for the active build

        Args:
            :parameters (dict): dictionary of all parameters used to gen rpm
            :version (str):  the version of the current build, e.g. 1.6.7

        Returns:
            parameters, TYPE: dict

        """
        if parameters is None:
            parameters = self.parameter_dict

        for k, v in parameters.items():
            if isinstance(v, dict):
                self.create(v)
            else:
                if k == 'Version':
                    parameters[k] = self.major
                elif k == 'Release':
                    parameters[k] = self.minor
                elif k == 'Source':
                    parameters[k] = PROJECT + '-' + self.major + '.' + self.minor + '.tar.gz'
                elif k == 'BuildDirName':
                    parameters[k] = PROJECT + '-' + self.major
        return parameters


def valid_version(parameter, min=0, max=100):
    """
    Summary.

        User input validation.  Validates version string made up of integers.
        Example:  '1.6.2'.  Each integer in the version sequence must be in
        a range of > 0 and < 100. Maximum version string digits is 3
        (Example: 0.2.3 )

    Args:
        :parameter (str): Version string from user input
        :min (int): Minimum allowable integer value a single digit in version
            string provided as a parameter
        :max (int): Maximum allowable integer value a single digit in a version
            string provided as a parameter

    Returns:
        True if parameter valid or None, False if invalid, TYPE: bool

    """
    # type correction and validation
    if parameter is None:
        return True

    elif isinstance(parameter, int):
        return False

    elif isinstance(parameter, float):
        parameter = str(parameter)

    component_list = parameter.split('.')
    length = len(component_list)

    try:

        if length <= 3:
            for component in component_list:
                if isinstance(int(component), int) and int(component) in range(min, max + 1):
                    continue
                else:
                    return False

    except ValueError as e:
        return False
    return True


def init_cli():
    """Collect parameters and call main."""
    try:
        parser = argparse.ArgumentParser(add_help=False)
        args = options(parser)
    except Exception as e:
        help_menu()
        stdout_message(str(e), 'ERROR')
        return exit_codes['E_MISC']['Code']

    if args.debug:
        print(debug_header)
        stdout_message(
                message='Set (--set-version):\t{}'.format(args.set),
                prefix='DBUG'
            )
        stdout_message(
                message='Build Flag (--build):\t{}'.format(args.build),
                prefix='DBUG'
            )
        stdout_message(
                message='Docker Image (--distro):\t{}'.format(args.distro),
                prefix='DBUG'
            )
        stdout_message(
                message='Debug Flag:\t\t{}'.format(args.debug),
                prefix='DBUG'
            )

    if len(sys.argv) == 1:
        help_menu()
        return exit_codes['EX_OK']['Code']

    elif args.help:
        help_menu()
        return exit_codes['EX_OK']['Code']

    elif args.build:
        if valid_version(args.set) and prebuild(TMPDIR, VOLMNT, git_root() + '/' + PACKAGE_CONFIG):
            package, contents = main(
                        setVersion=args.set,
                        environment=args.distro,
                        force=args.force,
                        debug=args.debug
                    )

            if package:
                stdout_message(f'New package created: {yl + package + rst}')
                stdout_message(f'RPM build process completed successfully. End', prefix='OK')

                if contents:
                    display_package_contents(package, contents)
                else:
                    stdout_message(
                        message=f'Unable to locate a rpm contents file in {build_root}.',
                        prefix='WARN'
                    )
                    return False

                return exit_codes['EX_OK']['Code']
            else:
                stdout_message(
                    '{}: Problem creating rpm installation package. Exit'.format(inspect.stack()[0][3]),
                    prefix='WARN',
                    severity='WARNING'
                )
                return exit_codes['E_MISC']['Code']

        elif not valid_version(args.set):
            stdout_message(
                'You must enter a valid version when using --set-version parameter. Ex: 1.6.3',
                prefix='WARN',
                severity='WARNING'
                )
            return exit_codes['E_DEPENDENCY']['Code']
        else:
            logger.warning('{} Failure in prebuild stage'.format(inspect.stack()[0][3]))
            return exit_codes['E_DEPENDENCY']['Code']
    return True


sys.exit(init_cli())
