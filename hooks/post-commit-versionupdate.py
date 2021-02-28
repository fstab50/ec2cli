#!/usr/bin/env python3
"""

   - Summary:   Post commit hook, updates version throughout project
   - Location:  .git/hooks
   - Filename:  commit-msg

"""
import os
import sys
import re
from shutil import copy2 as copyfile
import inspect


def packagename(filename):
    with open(filename) as p1:
        for line in p1.readlines():
            if 'PACKAGE' in line:
                return line.split(':')[1].strip()
                break


PACKAGE = packagename('DESCRIPTION.rst') or None
pattern = re.compile('^\* Version')

if PACKAGE is None:
    print('Problem executing post-commit-hook (%s). Exit' % __file__)
    sys.exit(1)
else:
    #sys.path.insert(0, os.path.abspath(PACKAGE))
    # copy version file to repository root for import parsing:
    copyfile('core/version.py', '_version.py')
    sys.exit(0)
    from _version import __version__
    os.remove('_version.py')
    #sys.path.pop(0)


try:
    with open('README.md') as f1:
        lines = f1.readlines()
        for index, line in enumerate(lines):
            if 'Version:' in line:
                newline = '  Version: ' + __version__ + '\n'
                lines[index] = newline
                break

            elif pattern.match(line):
                newline = '**Version**: ' + __version__ + '\n'
                lines[index] = newline
                break

        f1.close()
        with open('README.md', 'w') as f3:
            f3.writelines(lines)
except OSError as e:
    print(
            '%s: Error while reading or writing post-commit-hook (%s)' %
            (inspect.stack()[0][3], e)
        )
sys.exit(0)
