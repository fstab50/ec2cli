"""
Summary:
    Std Logging Module | FileHandler

Returns:
    logger object (logging)
"""
import os
import logging


# globals
pkg = 'ec2cli'
pkg_root = '/'.join(os.getcwd().split('/')[:-1])
log_file = pkg + '.log'
log_path = pkg_root + '/' + log_file

# log format - file
file_format = '%(asctime)s - %(pathname)s - %(name)s - [%(levelname)s]: %(message)s'
asctime_format = "%Y-%m-%d %H:%M:%S"


def getLogger(*args, **kwargs):
    """ std file handler logger """
    logger = logging.getLogger(*args, **kwargs)
    logger.propagate = False

    try:
        if not logger.handlers:
            # file handler
            f_handler = logging.FileHandler(log_path)
            f_formatter = logging.Formatter(file_format, asctime_format)
            f_handler.setFormatter(f_formatter)
            logger.addHandler(f_handler)
            logger.setLevel(logging.DEBUG)

    except OSError as e:
        raise e
    return logger
