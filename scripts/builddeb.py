#!/usr/bin/env python3
"""
Summary.

    builddeb (python3):  gcreds binary operating system package (.deb, Debian systems)

        - Automatic determination of version to be built
        - Build version can optionally be forced to a specific version
        - Resulting .deb package produced in packaging/deb directory
        - To execute build, from the directory of this module, run:

    .. code-block:: python

        $ cd ../<project dir>
        $ make builddeb

Author:
    Blake Huber
    Copyright 2017-2021, All Rights Reserved.

License:
    General Public License v3
    Additional terms may be found in the complete license agreement:
    https://bitbucket.org/blakeca00/gcreds/src/master/LICENSE.md

OS Support:
    - Debian, Ubuntu, Ubuntu variants

Dependencies:
    - Requires python3, developed and tested under python3.8
"""
import argparse
import os
import sys
import inspect
import re
import subprocess
import time
from shutil import copy2 as copyfile
from shutil import copytree, rmtree, which
from pyaws.utils import stdout_message
from pyaws.colors import Colors
from __init__ import logger                 # global logger


try:
    from pyaws.core.oscodes_unix import exit_codes
except Exception:
    from pyaws.core.oscodes_win import exit_codes    # non-specific os-safe codes


# globals
PROJECT = 'gcreds'
module = os.path.basename(__file__)
act = Colors.ORANGE                     # accent highlight (bright orange)
bd = Colors.BOLD + Colors.WHITE         # title formatting
bn = Colors.CYAN                        # color for main binary highlighting
lk = Colors.DARK_BLUE                    # color for filesystem path confirmations
red = Colors.RED                        # color for failed operations
yl = Colors.GOLD3                       # color when copying, creating paths
rst = Colors.RESET                      # reset all color, formatting


def git_root():
    """
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

          Builds an installable package (.deb) for Debian, Ubuntu, and Ubuntu
          variants of the Linux Operatining System

  ''' + bd + '''OPTIONS''' + rst + '''

            $ python3  ''' + act + module + rst + '''  --build  [ --force-version <VERSION> ]

                         -b, --build
                        [-d, --debug  ]
                        [-f, --force  ]
                        [-h, --help   ]
                        [-s, --set-version  <value> ]

        ''' + bd + '''-b''' + rst + ''', ''' + bd + '''--build''' + rst + ''':  Build Operating System package (.deb, Debian systems)
            When given without -S (--set-version) parameter switch, build ver-
            sion is extracted from the project repository information

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
    pkgmgr = 'apt'
    pkgmgr_bkup = 'apt-cache'

    if which(binary):

        if which(pkgmgr):
            cmd = pkgmgr + ' show ' + binary + ' 2>/dev/null | grep Version | head -n1'
        elif which(pkgmgr_bkup):
            cmd = pkgmgr_bkup + ' policy ' + binary + ' 2>/dev/null | grep Installed'

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


def create_builddirectory(path, version, force):
    """
    Summary:
        - Creates the deb package binary working directory
        - Checks if build artifacts preexist; if so, halts
        - If force is True, continues even if artifacts exist (overwrites)
    Returns:
        Success | Failure, TYPE: bool
    """
    try:

        builddir = PROJECT + '-' + version + '_amd64'

        # rm builddir when force if exists
        if force is True and builddir in os.listdir(path):
            rmtree(path + '/' + builddir)

        elif force is False and builddir in os.listdir(path):
            stdout_message(
                'Cannot create build directory {} - preexists. Use --force option to overwrite'.format(builddir),
                prefix='WARN',
                severity='WARNING'
                )
            return None

        # create build directory
        os.mkdir(path + '/' + builddir)

    except OSError as e:
        logger.exception(
            '{}: Unable to create build directory {}'.format(inspect.stack()[0][3], builddir)
            )
    return builddir


def builddir_structure(root, builddir):
    """
    Summary:
        - Updates path in binary exectuable
        - Updates
    Args:
        :root (str): full path to root directory of the git project
        :builddir (str): name of current build directory which we need to populate
    Vars:
        :core_dir (str): src path to library modules in project root
        :builddir_path (str): dst path to root of the current build directory
         (/<path>/gcreds-1.X.X dir)
    Returns:
        Success | Failure, TYPE: bool
    """
    project_dir = root.split('/')[-1]
    build_root = root + '/packaging/deb'
    core_dir = root + '/' + 'core'
    builddir_path = build_root + '/' + builddir
    debian_dir = 'DEBIAN'
    debian_path = build_root + '/' + debian_dir
    binary_path = builddir_path + '/usr/local/bin'
    comp_src = root + '/' + 'bash'
    comp_dst = builddir_path + '/etc/bash_completion.d'
    lib_path = builddir_path + '/usr/local/lib/' + PROJECT
    arrow = yl + Colors.BOLD + '-->' + rst

    try:

        stdout_message(f'Generating build structure and artifacts in {bn + builddir + rst}')

        if not os.path.exists(builddir_path + '/' + debian_dir):
            copytree(debian_path, builddir_path + '/' + debian_dir)
            # status msg
            _src_path = '../' + project_dir + debian_path.split(project_dir)[1]
            _dst_path = '../' + project_dir + (builddir_path + '/' + debian_dir).split(project_dir)[1]
            stdout_message(
                    message='Copied:\t{} {} {}'.format(lk + _src_path + rst, arrow, lk + _dst_path + rst),
                    prefix='OK'
                )

        if not os.path.exists(binary_path):
            os.makedirs(binary_path)
            _dst_path = '../' + project_dir + binary_path.split(project_dir)[1]
            stdout_message(
                    message='Created:\t{}'.format(lk + _dst_path + rst),
                    prefix='OK'
                )

        if not os.path.exists(binary_path + '/' + PROJECT):
            binary_src = PROJECT_ROOT + '/' + PROJECT
            binary_dst = binary_path + '/' + PROJECT
            copyfile(binary_src, binary_dst)
            # status msg
            _src_path = '../' + project_dir + binary_src.split(project_dir)[1]
            _dst_path = '../' + project_dir + binary_dst.split(project_dir)[1]
            stdout_message(
                    message='Copied:\t{} {} {}'.format(lk + _src_path + rst, arrow, lk + _dst_path + rst),
                    prefix='OK'
                )

        if not os.path.exists(lib_path):

            os.makedirs(lib_path)     # create library dir in builddir

            # status msg branching
            _dst_path = '../' + project_dir + lib_path.split(project_dir)[1]
            if os.path.exists(lib_path):
                stdout_message(
                        message='Created:\t{}'.format(lk + _dst_path + rst),
                        prefix='OK'
                    )
            else:
                stdout_message(
                        message='Failed to create:\t{}'.format(lk + _dst_path + rst),
                        prefix='FAIL'
                    )

        for libfile in os.listdir(core_dir):
            if os.path.exists(lib_path + '/' + libfile):
                stdout_message(f'{libfile} target exists - skip adding to builddir')

            if libfile.endswith('.log'):
                # log file, do not place in build
                logger.info(f'{libfile} is log file - skip adding to builddir')

            else:
                # place lib files in build
                lib_src = core_dir + '/' + libfile
                lib_dst = lib_path + '/' + libfile
                copyfile(lib_src, lib_dst)
                # status msg
                _src_path = '../' + project_dir + lib_src.split(project_dir)[1]
                _dst_path = '../' + project_dir + lib_dst.split(project_dir)[1]
                stdout_message(
                        message='Copied:\t{} {} {}'.format(lk + _src_path + rst, arrow, lk + _dst_path + rst),
                        prefix='OK'
                    )

        if not os.path.exists(comp_dst):
            # create path
            os.makedirs(comp_dst)
            _dst_path = '../' + project_dir + comp_dst.split(project_dir)[1]
            stdout_message(
                    message='Created:\t{}'.format(lk + _dst_path + rst),
                    prefix='OK'
                )

            # copy
            for artifact in list(filter(lambda x: x.endswith('.bash'), os.listdir(comp_src))):
                copyfile(comp_src + '/' + artifact, comp_dst + '/' + artifact)

    except OSError as e:
        logger.exception(
            '{}: Problem creating dirs on local fs'.format(inspect.stack()[0][3]))
        return False
    return True


def build_package(build_root, builddir):
    """
    Summary:
        Creates actual .deb package for current build, build version
    Returns:
        Success | Failure, TYPE: bool
    """
    try:

        pwd = os.getcwd()
        os.chdir(build_root)

        if os.path.exists(builddir):
            cmd = 'dpkg-deb --build ' + builddir + ' 2>/dev/null'
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


def builddir_content_updates(root, build_root, builddir, binary, version):
    """
    Summary.

        Updates builddir contents:
        - main exectuable has path to libraries updated
        - builddir DEBIAN/control file version is updated to current
        - updates the version.py file if version != to __version__
          contained in the file.  This occurs if user invokes the -S /
          --set-version option
    Args:
        :root (str): project root full fs path
        :builddir (str): dirname of the current build directory
        :binary (str): name of the main exectuable
        :version (str): version label provided with --set-version parameter. None otherwise
    Returns:
        Success | Failure, TYPE: bool

    """
    project_dir = git_root().split('/')[-1]
    version_module = 'version.py'
    builddir_path = build_root + '/' + builddir
    debian_dir = 'DEBIAN'
    debian_path = builddir_path + '/' + debian_dir
    control_file = 'control'
    binary_path = builddir_path + '/usr/local/bin'
    lib_path = builddir_path + '/usr/local/lib/' + PROJECT

    try:
        # main exec bin: update pkg_lib path, LOG_DIR
        with open(binary_path + '/' + binary) as f1:
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
        with open(binary_path + '/' + binary, 'w') as f3:
            f3.writelines(f2)
            path = project_dir + (binary_path + '/' + binary)[len(root):]
            stdout_message('Bin {} successfully updated.'.format(yl + path + rst))

        # debian control files
        with open(debian_path + '/' + control_file) as f1:
            f2 = f1.readlines()
            for index, line in enumerate(f2):
                if line.startswith('Version:'):
                    newline = 'Version: ' + version + '\n'
                    f2[index] = newline
            f1.close()

        # rewrite file
        with open(debian_path + '/' + control_file, 'w') as f3:
            f3.writelines(f2)
            path = project_dir + (debian_path + '/' + control_file)[len(root):]
            stdout_message('Control file {} successfully updated.'.format(yl + path + rst))

        # rewrite version file with current build version in case delta
        with open(lib_path + '/' + version_module, 'w') as f3:
            f2 = ['__version__=\"' + version + '\"\n']
            f3.writelines(f2)
            path = project_dir + (lib_path + '/' + version_module)[len(root):]
            stdout_message('Module {} successfully updated.'.format(yl + path + rst))

    except OSError as e:
        logger.exception(
            '%s: Problem while updating builddir contents: %s' %
            (inspect.stack()[0][3], str(e)))
        return False
    return True


def display_package_contents(build_root, version):
    """
    Summary:
        Output newly built package contents.
    Args:
        :build_root (str):  location of newly built rpm package
        :version (str):  current version string, format:  '{major}.{minor}.{patch num}'
    Returns:
        Success | Failure, TYPE: bool
    """
    pkg_path = None

    for f in os.listdir(build_root):
        if f.endswith('.deb') and re.search(version, f):
            pkg_path = build_root + '/' + f

    if pkg_path is None:
        stdout_message(
            message=f'Unable to locate a build package in {build_root}. Abort build.',
            prefix='WARN'
        )
        return False

    tab = '\t'.expandtabs(2)
    width = 80
    path, package = os.path.split(pkg_path)
    os.chdir(path)
    cmd = 'dpkg-deb --contents ' + package
    r = subprocess.getoutput(cmd)
    formatted_out = r.splitlines()

    # title header and subheader
    header = '\n\t\tPackage Contents:  ' + bd + package + rst + '\n'
    print(header)
    subheader = tab + 'Permission' + tab + 'Owner/Group' + '\t' + 'ctime' \
        + '\t'.expandtabs(8) + 'File'
    print(subheader)

    # divider line
    list(filter(lambda x: print('-', end=''), range(0, width + 1))), print('\r')

    # content
    for line in formatted_out:
        prefix = [tab + x for x in line.split()[:2]]
        raw = line.split()[2:4]
        content_path = line.split()[5]
        fline = ''.join(prefix) + '\t'.join(raw[:4]) + tab + yl + content_path + rst
        print(fline)
    return True


def main(setVersion, force, debug):
    """
    Summary:
        Create build directories, populate contents, update contents
    Returns:
        Success | Failure, TYPE: bool
    """
    global PROJECT_BIN
    PROJECT_BIN = 'gcreds'
    global PROJECT_ROOT
    PROJECT_ROOT = git_root()
    global SCRIPT_DIR
    SCRIPT_DIR = PROJECT_ROOT + '/' + 'scripts'
    global BUILD_ROOT
    BUILD_ROOT = PROJECT_ROOT + '/packaging/deb'
    global CURRENT_VERSION
    CURRENT_VERSION = current_version(PROJECT_BIN)

    # sort out version numbers, forceVersion is override      #
    # for all info contained in project                       #

    global VERSION
    if setVersion:
        VERSION = setVersion

    elif CURRENT_VERSION:
        VERSION = increment_version(CURRENT_VERSION)

    else:
        stdout_message('Could not determine current {} version'.format(bd + PROJECT + rst))
        sys.exit(exit_codes['E_DEPENDENCY']['Code'])

    # log
    stdout_message(f'Current version of last build: {CURRENT_VERSION}')
    stdout_message(f'Version to be used for this build: {VERSION}')

    # create initial binary working dir
    BUILDDIRNAME = create_builddirectory(BUILD_ROOT, VERSION, force)

    if BUILDDIRNAME:

        r_struture = builddir_structure(PROJECT_ROOT, BUILDDIRNAME)

        r_updates = builddir_content_updates(
                PROJECT_ROOT, BUILD_ROOT, BUILDDIRNAME, PROJECT_BIN, VERSION
            )

        if r_struture and r_updates and build_package(BUILD_ROOT, BUILDDIRNAME):
            return postbuild(VERSION, BUILD_ROOT + '/' + BUILDDIRNAME, debug)

    return False


def options(parser, help_menu=False):
    """
    Summary:
        parse cli parameter options
    Returns:
        TYPE: argparse object, parser argument set
    """
    parser.add_argument("-b", "--build", dest='build', default=False, action='store_true', required=False)
    parser.add_argument("-d", "--debug", dest='debug', default=False, action='store_true', required=False)
    parser.add_argument("-F", "--force", dest='force', default=False, action='store_true', required=False)
    parser.add_argument("-s", "--set-version", dest='set', default=None, nargs='?', type=str, required=False)
    parser.add_argument("-h", "--help", dest='help', default=False, action='store_true', required=False)
    return parser.parse_args()


def prebuild():
    """
    Summary.

        Prerequisites and dependencies for build execution

    """
    version_module = 'version.py'

    try:
        root = git_root()
        src = root + '/core' + '/' + version_module
        dst = root + '/scripts' + '/' + version_module
        copyfile(src, dst)
        global __version__
        from version import __version__
    except Exception as e:
        logger.exception(
            '{}: Failure to import _version module _version'.format(inspect.stack()[0][3])
        )
        return False
    return True


def postbuild(version, builddir_path, debug):
    """
    Summary.

        Post-build clean up

    Returns:
        Success | Failure, TYPE: bool

    """
    root = git_root()
    scripts_dir = SCRIPT_DIR
    project_dir = root.split('/')[-1]
    version_module = 'version.py'

    try:

        # remove temp version module copied to scripts dir
        if os.path.exists(scripts_dir + '/' + version_module):
            os.remove(scripts_dir + '/' + version_module)

        # remove build directory, residual artifacts
        if os.path.exists(builddir_path) and not debug:
            rmtree(builddir_path)

        # rewrite version file with current build version
        with open(root + '/core/' + version_module, 'w') as f3:
            f2 = ['__version__=\"' + version + '\"\n']
            f3.writelines(f2)
            path = project_dir + (root + '/core/' + version_module)[len(root):]
            stdout_message(
                '{}: Module {} successfully updated.'.format(inspect.stack()[0][3], yl + path + rst)
                )

    except OSError as e:
        logger.exception('{}: Postbuild clean up failure'.format(inspect.stack()[0][3]))
        return False
    return display_package_contents(BUILD_ROOT, VERSION)


def valid_version(parameter, min=0, max=100):
    """
    Summary:
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
    """ Collect parameters and call main """
    try:
        parser = argparse.ArgumentParser(add_help=False)
        args = options(parser)
    except Exception as e:
        help_menu()
        stdout_message(str(e), 'ERROR')
        return exit_codes['E_MISC']['Code']

    if args.debug:
        stdout_message(
                message='set-version:\t{}'.format(args.set),
                prefix='DBUG',
                severity='WARNING'
            )
        stdout_message(
                message='build:\t{}'.format(args.build),
                prefix='DBUG',
                severity='WARNING'
            )
        stdout_message(
                message='debug flag:\t{}'.format(args.debug),
                prefix='DBUG',
                severity='WARNING'
            )

    if len(sys.argv) == 1:
        help_menu()
        return exit_codes['EX_OK']['Code']

    elif args.help:
        help_menu()
        return exit_codes['EX_OK']['Code']

    elif args.build:

        if valid_version(args.set) and prebuild():

            if main(setVersion=args.set, force=args.force, debug=args.debug):
                stdout_message(f'{PROJECT} build complete')
                return exit_codes['EX_OK']['Code']
            else:
                stdout_message(
                    '{}: Problem creating .deb installation package. Exit'.format(inspect.stack()[0][3]),
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
