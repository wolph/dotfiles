try:
    from jedi.utils import setup_readline
    setup_readline()
except ImportError:
    # Fallback to the stdlib readline completer if it is installed.
    # Taken from http://docs.python.org/2/library/rlcompleter.html
    print('Jedi is not installed, falling back to readline')
    try:
        import readline
    except ImportError:
        print('Readline is not installed either. No tab completion is '
              'enabled.')
    else:
        import rlcompleter
        assert rlcompleter
        readline.parse_and_bind('tab: complete')

