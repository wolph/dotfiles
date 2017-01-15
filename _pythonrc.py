try:
    from jedi.utils import setup_readline
    setup_readline()
except ImportError:
    # Fallback to the stdlib readline completer if it is installed.
    # Taken from http://docs.python.org/2/library/rlcompleter.html
    try:
        import readline
    except ImportError:
        pass
    else:
        import rlcompleter
        assert rlcompleter
        readline.parse_and_bind('tab: complete')

