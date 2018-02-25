"""
Summary:
    ANSI color and formatting code class
    See: http://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html#256-colors

Args:
    None

Returns:
    ansi codes

Raises:
    None
"""


class Colors():
    """
    Class attributes provide different format variations
    """
    # forground colors
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    DARKCYAN = '\033[36m'
    BLUE = '\033[94m'
    DARKBLUE = '\033[38;5;95;38;5;24m'
    GREEN = '\033[92m'
    DARKGREEN = '\u001b[38;5;2m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ORANGE = '\033[38;5;95;38;5;214m'
    WHITE = '\033[37m'
    LTGRAY = '\u001b[38;5;249m'
    DARKGRAY = '\033[90m'

    # background colors
    BKGND_WHITE_BOLD = '\u001b[47;1m'
    BKGND_WHITE = '\u001b[47m'
    BKGND_BLACK = '\u001b[40m'
    BKGND_RED = '\u001b[41m'
    BKGND_GREEN = '\u001b[42m'
    BKGND_YELLOW = '\u001b[43m'
    BKGND_BLUE = '\u001b[44m'
    BKGND_MAGENTA = '\u001b[45m'
    BKGND_CYAN = '\u001b[46m'

    # bright background colors
    BKGND_BRIGHT_BLACK = '\u001b[40;1m'
    BKGND_BRIGHT_RED = '\u001b[41;1m'
    BKGND_BRIGHT_GREEN = '\u001b[42;1m'
    BKGND_BRIGHT_YELLOW = '\u001b[43;1m'
    BKGND_BRIGHT_BLUE = '\u001b[44;1m'
    BKGND_BRIGHT_MAGENTA = '\u001b[45;1m'
    BKGND_BRIGHT_CYAN = '\u001b[46;1m'
    BKGND_BRIGHT_WHITE = '\u001b[47;1m'

    # formats
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    ITALIC = '\e[3m'
    END = '\033[0m'
    REVERSE = "\033[;7m"
    RESET = "\033[0;0m"

    # special formats
    URL = UNDERLINE + CYAN
    TITLE = UNDERLINE + BOLD
