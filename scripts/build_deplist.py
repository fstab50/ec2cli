"""
Summary:
    - Build OS Package dependency list
    - Executed during build stage

"""
import argparse
import os
import sys
import subprocess
from shutil import which
import distro
import loggers
import inspect
from pyaws.utils import stdout_message
from pyaws.colors import Colors

try:
    from pyaws.core.oscodes_unix import exit_codes
except Exception:
    from pyaws.core.oscodes_win import exit_codes    # non-specific os-safe codes

try:
    from version import __version__
except Exception:
    __version__ = '1.0'

# globals
PROJECT_BIN = 'buildpy'
TARGET_FUNC = 'binary_depcheck'             # name of function containing os package dependencies
TMPDIR = '/tmp'
module = os.path.basename(__file__)

# formatting
bd = Colors.BOLD + Colors.BRIGHT_WHITE
gr = Colors.BOLD + Colors.LT3GRAY
rd = Colors.RED
rst = Colors.RESET


logger = loggers.getLogger(__version__)


# --- declarations --------------------------------------------------------------------------------


def apply_alias(pkg_list):
    """
    Corrections for os packages listed in registry under different name
    """
    new = []
    for x in pkg_list:
        if x == 'awk':
            new.append('gawk')
        else:
            new.append(x)
    return new


def build_files(files, tabspaces=4):
    """
    Summary:
        Builds os pkg files in root/core directory
    Returns:
        Success | Failure, TYPE: bool
    """

    try:

        for file in files:

            desc = []

            with open('/tmp/' + file) as f3:
                f4 = f3.readlines()

            with open(root + '/core/' + file, 'w') as f5:
                for index, line in enumerate(f4):
                    if 'Package:' in line:
                        package = file.split('.')[0]
                        indented = '\n\t'.expandtabs(tabspaces) + bd + 'Package' + rst + ':  %s' % (rd + package + rst)
                        f5.write(indented)
                    elif 'Description:' in line:
                        header = '\n\n\t' + bd + line.split(':')[0] + ':' + rst
                        start = index
                        f4[start] = header + ''.join(line.split(':')[1:])

                desc.extend(f4[start:])
                f5.write(('\t' + str(desc[0]) + '\n').expandtabs(tabspaces))

                for line in desc[1:]:
                    indented = ('\t' + str(line)).expandtabs(tabspaces + 2)
                    f5.write(indented)
    except OSError as e:
        stdout_message(message=f'Problem generating pkg file {file}', prefix='FAIL')
        return False
    return True


def files_exist(root, files, force=False):
    """
    Summary:
        Determines if filesystem objects exist
    Args:
        :files (list): filename list
        :force (bool): if True, forces recreation of files (return False)
    Returns:
        True if exist | False if not exist
        TYPE: bool
    """

    lib_dir = get_library_path(root, PROJECT_BIN)

    exists = True

    try:
        if force:
            return False
        else:
            for file in files:
                if not os.path.exists(lib_dir + '/' + file):
                    exists = False
    except OSError as e:
        logger.exception(
                f'{inspect.stack()[0][3]}: Unable to determine existence of .pkg files')
    return exists


def get_library_path(root, binfile):
    """ Finds library dependency path """
    try:
        with open(root + '/' + binfile) as f1:
            f2 = f1.readlines()

        for line in f2:
            if line.startswith('pkg_lib='):
                return (root + '/' + line.split('=')[1].strip().split('/')[1])[:-1]
    except OSError as e:
        logger.exception(
                f'{inspect.stack()[0][3]}: Unable to determine existence of .pkg files'
            )
    return None


def git_root():
    """
    Returns root directory of git repository
    """
    cmd = 'git rev-parse --show-toplevel 2>/dev/null'
    return subprocess.getoutput(cmd).strip()


def os_packages_ubuntu(pkg_list, debug=False):
    """
    Summary:
        Extracts descriptions of OS packages using Debian package Manager(s)
    Returns:
        Tuple of filenames created
    """
    for package in pkg_list:

        if which('apt'):
            if not subprocess.getoutput('apt show ' + package + ' 2>/dev/null'):
                stdout_message(f'Skipping package {package} - No entry in pkg manager')
                continue
            else:
                cmd = 'apt show ' + package + ' 2>/dev/null > ' + TMPDIR + '/' + package + '.pkg'

        elif which('apt-cache'):
            if not subprocess.getoutput('apt-cache show ' + package + ' 2>/dev/null'):
                stdout_message(f'Skipping package {package} - No entry in pkg manager')
                continue
            else:
                cmd = 'apt-cache show ' + package + ' 2>/dev/null > ' + TMPDIR + '/' + package + '.pkg'

        subprocess.getoutput(cmd)
        stdout_message(f'Extracted package mgr contents for {package}', prefix='OK')

    return list(filter(lambda x: x.endswith('.pkg'), os.listdir(TMPDIR)))


def os_packages_redhat(pkg_list, debug=False):
    """
    Summary:
        Extracts descriptions of OS packages using Redhat or Fedora package Manager(s)
    Returns:
        Tuple of filenames created
    """
    if debug:
        tty = '/dev/tty'        # output to stdout
    else:
        tty = '/dev/null'       # silent

    for package in pkg_list:

        if which('yum') and which('tee'):
            cmd = 'yum info ' + package + ' | tee ' + tty + ' > ' + TMPDIR + '/' + package + '.pkg'
            stdout_message(subprocess.getoutput(cmd))

        if which('dnf') and which('tee'):
            cmd = 'dnf info ' + package + ' | tee ' + tty + ' > ' + TMPDIR + '/' + package + '.pkg'
            stdout_message(subprocess.getoutput(cmd))

    return list(filter(lambda x: x.endswith('.pkg'), os.listdir(TMPDIR)))


def options(parser):
    """
    Summary:
        parse cli parameter options
    Returns:
        TYPE: argparse object, parser argument set
    """
    parser.add_argument("-f", "--force", dest='force', action='store_true', required=False)
    parser.add_argument("-d", "--debug", dest='debug', action='store_true', default=False, required=False)
    parser.add_argument("-V", "--version", dest='version', action='store_true', required=False)
    return parser.parse_args()


def prerun_clean(dir):
    """ Removes any artifacts generated on previous run """
    try:
        for file in list(filter(lambda x: x.endswith('.pkg'), os.listdir(TMPDIR))):
            os.remove(TMPDIR + '/' + file)
        # validate version module
    except Exception as e:
        stdout_message(message=f'Problem cleaning artifacts prior to execution. Exit.', prefix='WARN')
    return True


# --- main -----------------------------------------------------------------------------------------


if __name__ == '__main__':

    parser = argparse.ArgumentParser(add_help=True)

    try:

        args = options(parser)

    except Exception as e:
        stdout_message(str(e), 'ERROR')
        sys.exit(exit_codes['EX_OK']['Code'])

    prerun_clean(TMPDIR)

    # begin
    root = git_root()
    os.chdir(root)

    with open(PROJECT_BIN) as f1:
        f2 = f1.readlines()

    for line in f2:
        if TARGET_FUNC in line and 'function' not in line:

            if args.debug:
                stdout_message(f'Line extracted from {PROJECT_BIN}:  {line}', prefix='DBUG')

            dep_list = line.split(TARGET_FUNC)[1].split(' ')

    dlist = ['gawk' if y == 'awk' else y for y in (x.strip() for x in dep_list) if y]

    # detect os using distro, use package mgr to pull descriptions of OS pkgs
    os_family = distro.linux_distribution()[0]

    stdout_message(message='Host OS identified as {}'.format(os_family))
    if os_family == 'Ubuntu' or 'Mint' in os_family:
        file_list = os_packages_ubuntu(dlist)

    elif os_family == 'Redhat':
        file_list = os_packages_redhat(dlist)

    stdout_message(f'File list generated: {file_list}')

    if files_exist(root, file_list) and not args.force:
        stdout_message(
                f'{module}:  Files in list already exist, use --force to recreate. Deplist Complete.'
            )
        sys.exit(0)

    elif build_files(file_list):
        stdout_message('Package files built successfully')
        sys.exit(0)

    else:
        stdout_message(
                message='Problem creating package files. Please check %s directory.' % root + '/core',
                prefix='WARN'
            )
        sys.exit(1)
