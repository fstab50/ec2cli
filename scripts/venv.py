"""
External module for sourcing the virtual environment
in Python projects
"""
import os
import subprocess
from libtools import stdout_message

environments = ['venv', 'p3_venv', 'p3_env']


def _git_root():
    """
    Summary.

        Returns root directory of git repository

    """
    cmd = 'git rev-parse --show-toplevel 2>/dev/null'
    return subprocess.getoutput(cmd).strip()


def source_venv():
    """
    Located the virtual environment in a Python project
    and activates it
    """
    root = _git_root()
    os.chdir(root)
    for d in os.listdir('.'):
        path = os.path.join(d, 'bin', 'activate')
        if os.path.exists(path):
            stdout_message('path is {}'.format(path))
            subprocess.getoutput('. {}'.format(path))
            return True
    return False
