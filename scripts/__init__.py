import os
from _version import __version__ as version
from pyaws import logd


__author__ = 'Blake Huber'
__version__ = version
__license__ = "MIT"
__maintainer__ = "Blake Huber"
__email__ = "blakeca00[AT]gmail.com"
__status__ = "Development"

HOME = os.environ.get('HOME')
PACKAGE = 'core'
enable_logging = True
log_mode = 'FILE'          # log to cloudwatch logs
log_filename = 'build_process.log'
log_dir = 'logs'
log_path = HOME + '/' + log_dir + '/' + log_filename


log_config = {
    "PROJECT": {
        "PACKAGE": PACKAGE,
        "CONFIG_VERSION": __version__,
    },
    "LOGGING": {
        "ENABLE_LOGGING": enable_logging,
        "LOG_FILENAME": log_filename,
        "LOG_DIR": log_dir,
        "LOG_PATH": log_path,
        "LOG_MODE": log_mode,
        "SYSLOG_FILE": False
    }
}

# global logger
logd.local_config = log_config
logger = logd.getLogger(__version__)
