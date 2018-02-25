"""
Standard OS Module Exit Codes
    - See https://docs.python.org/3.6/library/os.html#process-management

Module Attributes:
    - exit_codes (dict): exit error codes for Unix, Linux

"""

import os


# --- exit codes for Unix, Linux, Linux-based operating systems ----------------


exit_codes = {
    'EX_OK': {
        'Code': 0,
        'Reason': 'No error occurred'
    },
    'E_DEPENDENCY': {
        'Code': 1,
        'Reason': 'Missing required dependency'
    },
    'E_DIR': {
        'Code': 2,
        'Reason': 'Failure to create log dir, log file'
    },
    'E_ENVIRONMENT': {
        'Code': 3,
        'Reason': 'Incorrect shell, language interpreter, or operating system'
    },
    'EX_AWSCLI': {
        'Code': 4,
        'Reason': 'Value could not be determined from local awscli configuration'
    },
    'EX_NOPERM': {
        'Code': os.EX_NOPERM,
        'Reason': 'IAM user or role permissions do not allow this action'
    },
    'E_AUTHFAIL': {
        'Code': 5,
        'Reason': 'Authentication Fail'
    },
    'E_BADPROFILE': {
        'Code': 6,
        'Reason': 'Local profile variable not set or incorrect'
    },
    'E_USER_CANCEL': {
        'Code': 7,
        'Reason': 'User abort'
    },
    'E_BADARG': {
        'Code': 8,
        'Reason': 'Bad input parameter'
    },
    'E_EXPIRED_CREDS': {
        'Code': 9,
        'Reason': 'Credentials expired or otherwise no longer valid'
    },
    'E_MISC': {
        'Code': 9,
        'Reason': 'Unknown Error'
    },
    'EX_NOUSER': {
        'Code': os.EX_NOUSER,
        'Reason': 'specified user does not exist'
    },
    'EX_CONFIG': {
        'Code': os.EX_CONFIG,
        'Reason': 'Configuration or config parameter error'
    },
    'EX_CREATE_FAIL': {
        'Code': 21,
        'Reason': 'Keyset failed to create. Possible Permissions issue'
    },
    'EX_DELETE_FAIL': {
        'Code': 22,
        'Reason': 'Keyset failed to delete.  Possible Permissions issue'
    },
    'EX_DATAERR': {
        'Code': os.EX_DATAERR,
        'Reason': 'Input data incorrect'
    },
    'EX_NOINPUT': {
        'Code': os.EX_NOINPUT,
        'Reason': 'Input file does not exist or not readable.'
    },
    'EX_UNAVAILABLE': {
        'Code': os.EX_UNAVAILABLE,
        'Reason': 'Required service or dependency unavailable.'
    },
    'EX_PROTOCOL': {
        'Code': os.EX_PROTOCOL,
        'Reason': 'Protocol exchange was illegal, invalid, or not understood.'
    },
    'EX_OSERR': {
        'Code': os.EX_OSERR,
        'Reason': 'Operating system error.'
    },
    'EX_OSFILE': {
        'Code': os.EX_OSFILE,
        'Reason': 'System file does not exist, or could not be opened'
    },
    'EX_IOERR': {
        'Code': os.EX_IOERR,
        'Reason': 'Exit code that means that an error occurred while doing I/O on some file.'
    },
    'EX_NOHOST': {
        'Code': os.EX_NOHOST,
        'Reason': 'Network host does not exist or not found'
    },
    'EX_SOFTWARE': {
        'Code': os.EX_SOFTWARE,
        'Reason': 'Internal software error detected.'
    },
    'EX_CANTCREAT': {
        'Code': os.EX_CANTCREAT,
        'Reason': 'User specified output file could not be created.'
    }
}
