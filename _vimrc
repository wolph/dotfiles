""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Must Have
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" get out of horrible vi-compatible mode
set nocompatible 
" we are using a dark background
set background=dark 
" disable everything until we've loaded the bundles
filetype off 

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Install Plug if it's not installed
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let iCanHazPlug=1
let plugPath=expand('~/.vim/autoload/plug.vim')
if !filereadable(plugPath)
    echo "Installing Plug to " . plugPath 
    echo ""
    if has("win32")
        silent !curl -Lqo .vim\autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        source .vim\autoload\plug.vim
    else
        if executable('curl')
            silent !curl -Lqo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        else
            silent !curl -qO ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        endif

        source ~/.vim/autoload/plug.vim
    endif
    let iCanHazPlug=0
endif

if has("win32")
    source .vim\autoload\plug.vim
endif

let g:plug_threads=64

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Make sure neovim doesn't use the virtualenv
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has("nvim")
    if filereadable('/usr/local/bin/python2')
        let g:python_host_prog = '/usr/local/bin/python2'
    else
        let g:python_host_prog = '/usr/bin/python2'
    endif

    if filereadable('/usr/local/bin/python3')
        let g:python3_host_prog = '/usr/local/bin/python3'
    else
        let g:python3_host_prog = '/usr/bin/python3'
    endif
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Check python version if available
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has("python")
    python import vim; from sys import version_info as v; vim.command('let python_version=%d' % (v[0] * 100 + v[1]))
else
    let python_version=0
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Load and install the Plugs using Plug
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin(expand('~/.vim/bundle'))
" Tree like file browser
" Plug 'WoLpH/nerdtree', {'tag': 'patch-1'}
Plug 'scrooloose/nerdtree'
" A Git wrapper so awesome, it should be illegal
Plug 'tpope/vim-fugitive'
" Easier way to move around in Vim
Plug 'Lokaltog/vim-easymotion'
" Snipmate and requirements for TextMate snippets
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-repeat'
Plug 'lepture/vim-jinja'
Plug 'thiderman/vim-supervisor'
Plug 'evanmiller/nginx-vim-syntax'
Plug 'alfredodeza/coveragepy.vim'
Plug 'alfredodeza/pytest.vim'
Plug 'pig.vim'
if python_version >= 205
    " Uses with_statement so python 2.5 or higher
    Plug 'jmcantrell/vim-virtualenv'
endif
" Dash support
Plug 'rizzatti/dash.vim'
Plug 'vim-coffee-script'
Plug 'tshirtman/vim-cython'
Plug 'logstash.vim'
" Plug 'clickable.vim'

" Javascript/html indending
Plug 'pangloss/vim-javascript'
Plug 'rstacruz/sparkup'

Plug 'markcornick/vim-vagrant'
if has('mac')
    Plug 'copy-as-rtf'
endif
Plug 'mikewest/vimroom'
Plug 'guns/xterm-color-table.vim'

Plug 'tfnico/vim-gradle'
Plug 'zainin/vim-mikrotik'
Plug 'Chiel92/vim-autoformat'
Plug 'indentpython.vim'
Plug 'gorkunov/smartpairs.vim'

" Easy import sorting for Python
map <leader>i :Isort<cr>
command! -range=% Isort :<line1>,<line2>! isort -

if isdirectory('/usr/local/opt/fzf') || isdirectory(expand('~/.fzf'))
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Fuzzy finder (fzf)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    if isdirectory('/usr/local/opt/fzf')
        Plug '/usr/local/opt/fzf'
    else
        Plug expand('~/.fzf')
    endif

    Plug 'junegunn/fzf.vim'

    " This is the default extra key bindings
    let g:fzf_action = {
    \ 'ctrl-t': 'tab split',
    \ 'ctrl-x': 'split',
    \ 'ctrl-v': 'vsplit' }

    let g:fzf_command_prefix = ''

    " [Tags] Command to generate tags file
    " let g:fzf_tags_command = 'ctags -R'
    " let g:fzf_tags_command = 'ctags -R $VIRTUAL_ENV/lib/python2.7/site-packages $VIRTUAL_ENV/lib/python3.4/site-packages $VIRTUAL_ENV/lib/python3.5/site-packages $VIRTUAL_ENV/lib/python3.6/site-packages ${PWD}'
    let g:fzf_tags_command = 'ctags -R --fields=+l --languages=python --python-kinds=-iv -f ./tags $(python -c "import os, sys; print('' ''.join(''{}''.format(d) for d in sys.path if os.path.isdir(d)))")'

    " Default fzf layout
    " - down / up / left / right
    let g:fzf_layout = { 'down': '~70%' }

    " In Neovim, you can set up fzf window using a Vim command
    let g:fzf_layout = { 'window': 'enew' }
    let g:fzf_layout = { 'window': '-tabnew' }

    " Customize fzf colors to match your color scheme
    let g:fzf_colors =
        \ {'fg':      ['fg', 'Normal'],
         \ 'bg':      ['bg', 'Normal'],
         \ 'hl':      ['fg', 'Comment'],
         \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
         \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
         \ 'hl+':     ['fg', 'Statement'],
         \ 'info':    ['fg', 'PreProc'],
         \ 'prompt':  ['fg', 'Conditional'],
         \ 'pointer': ['fg', 'Exception'],
         \ 'marker':  ['fg', 'Keyword'],
         \ 'spinner': ['fg', 'Label'],
         \ 'header':  ['fg', 'Comment'] }

    " Enable per-command history.
    " CTRL-N and CTRL-P will be automatically bound to next-history and
    " previous-history instead of down and up. If you don't like the change,
    " explicitly bind the keys to down and up in your $FZF_DEFAULT_OPTS.
    let g:fzf_history_dir = '~/.local/share/fzf-history'

    " [Files] Extra options for fzf
    "   e.g. File preview using Highlight
    "        (http://www.andre-simon.de/doku/highlight/en/highlight.html)
    let g:fzf_files_options =
    \ '--preview "(highlight -O ansi {} || cat {}) 2> /dev/null | head -'.&lines.'"'

    " [Buffers] Jump to the existing window if possible
    let g:fzf_buffers_jump = 1

    " [[B]Commits] Customize the options used by 'git log':
    let g:fzf_commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'

    " [Tags] Command to generate tags file
    let g:fzf_tags_command = 'ctags -R'

    " [Commands] --expect expression for directly executing the command
    let g:fzf_commands_expect = 'alt-enter,ctrl-x'

    nmap <c-t> :FZF<cr>
    imap <c-x><c-o> <plug>(fzf-complete-line)
    map <leader>b :Buffers<cr>
    map <leader>f :Files<cr>
    map <leader>g :GFiles<cr>
    map <leader>t :Tags<cr>
else
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CtrlP is a plugin to quickly open files
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    Plug 'kien/ctrlp.vim'

    " Change mapping since I prefer ^t
    let g:ctrlp_map = '<c-t>'
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" YouCompleteMe
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" if has("nvim")
"     Plug 'Valloric/YouCompleteMe'
"     let g:ycm_path_to_python_interpreter = '/usr/local/bin/python2'
" endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Deoplete autocompleter 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has("nvim")
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
	let g:deoplete#enable_at_startup = 1
	if !exists('g:deoplete#omni#input_patterns')
  		let g:deoplete#omni#input_patterns = {}
	endif
	" let g:deoplete#disable_auto_complete = 1
	autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

	" omnifuncs
	augroup omnifuncs
  		autocmd!
  		autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
  		autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
  		autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
  		autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
  		autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
	augroup end
	" tern
	if exists('g:plugs["tern_for_vim"]')
  		let g:tern_show_argument_hints = 'on_hold'
  		let g:tern_show_signature_in_pum = 1
  		autocmd FileType javascript setlocal omnifunc=tern#Complete
	endif

	" deoplete tab-complete
	inoremap <expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"
	" tern
	autocmd FileType javascript nnoremap <silent> <buffer> gb :TernDef<CR>
endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ansible Vim syntax
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'chase/vim-ansible-yaml'
let g:ansible_options = {'ignore_blank_lines': 0}
let g:ansible_options = {'documentation_mapping': '<C-K>'}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Gundo, the holy grail in undos
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'dsummersl/gundo.vim'
nnoremap U :silent GundoToggle<CR>
let g:gundo_verbose_graph=0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Snippets
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Track the engine.

Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tomtom/tlib_vim'
Plug 'garbas/vim-snipmate'

" Lots of snippets
Plug 'honza/vim-snippets'
" snippets for BibTeX files
Plug 'rbonvall/snipmate-snippets-bib'
" snippets for Arduino files
Plug 'sudar/vim-arduino-snippets'
" snippets for Twitter Bootstrap markup, in HTML and Haml
Plug 'bonsaiben/bootstrap-snippets'


" Rainbow parenthesis
Plug 'luochen1990/rainbow'
let g:rainbow_active=1

" " If you want :UltiSnipsEdit to split your window.
" let g:UltiSnipsEditSplit="vertical"

command! -nargs=1 Silent
\ | execute ':silent !'.<q-args>
\ | execute ':redraw!'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Check flake8 whenever a Python file is written
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plug 'nvie/vim-flake8'
" autocmd BufWritePost *.py call Flake8()
" let g:flake8_show_quickfix=0
" let g:flake8_show_in_gutter=1
" let g:flake8_show_in_file=0
" Plug 'andviro/flake8-vim'
" let g:PyFlakeOnWrite = 1
" let g:PyFlakeCWindow = 0 
" let g:PyFlakeDisabledMessages = 'W391'
" 
" " Remove trailing whitespace in Python before saving
" autocmd BufWritePre *.py :%s/\s\+$//e

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable the system clipboard if available
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if has("clipboard")
  set clipboard=unnamed " copy to the system clipboardA
  set mouse=n

  if has("unnamedplus") " X11 support
    set clipboard+=unnamedplus
  endif
endif

" Toggle paste mode with ctrl+i
set pastetoggle=<C-i>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Surround text/selection with tags
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'tpope/vim-surround'

autocmd FileType rst let g:surround_{char2nr(':')} = ":\1command\1:`\r`"
autocmd FileType rst vmap m S:math<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" reStructuedText in Vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plug 'Rykka/riv.vim'
" Set the default path for Riv (Not supported yet, will work in 0.75 and up)
let g:riv_default_path = "~/Desktop/TU"
let main_project = {'path': './',  'build_path': 'build'}
let sphinx_project = {'path': './docs/',  'build_path': './docs/_build'}
let g:riv_projects = [main_project, sphinx_project]

" Set the default (web|file)browser for OS X
let g:riv_ft_browser = "open"
let g:riv_web_browser = "open"
let g:riv_file_link_style = 2

augroup filetypedetect
    au BufNewFile,BufRead *.rst set suffixesadd+=.rst
augroup END
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Supertab so we can <Tab> for autocompletion
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'ervandew/supertab'

let g:SuperTabDefaultCompletionType = "context"
let g:SuperTabContextDefaultCompletionType = "<c-x><c-o>"

" I prefer to let the completion go from top to bottom
" let g:SuperTabDefaultCompletionType = "<c-n>"

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Syntastic, uber awesome syntax and errors highlighter
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Syntastic is awesome, but slow as ... on Vim
" if version >= 702
if has("nvim")
    Plug 'Syntastic' 

    " shouldn't do Python for us
    let g:syntastic_python_checkers = []
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Python Mode
"
" Lint, code completion, documentation lookup, jumping to classes/methods,
" etc... Essential package for Python development
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" if python_version >= 205
"     Plug 'klen/python-mode'
"     Plug 'klen/rope-vim'
" endif
" " Python-mode
" " Activate rope
" " Keys:
" " K             Show python docs
" " <Ctrl-Space>  Rope autocomplete
" " <Ctrl-c>g     Rope goto definition
" " <Ctrl-c>d     Rope show documentation
" " <Ctrl-c>f     Rope find occurrences
" " <Leader>b     Set, unset breakpoint (g:pymode_breakpoint enabled)
" " [[            Jump on previous class or function (normal, visual, operator modes)
" " ]]            Jump on next class or function (normal, visual, operator modes)
" " [M            Jump on previous class or method (normal, visual, operator modes)
" " ]M            Jump on next class or method (normal, visual, operator modes)
" 
" " No need for Rope completion with Jedi
" " Load rope plugin
" let g:pymode_rope = 1
" 
" " Map keys for autocompletion
" let g:pymode_rope_autocomplete_map = '<C-Space>'
" 
" " Auto create and open ropeproject
" let g:pymode_rope_auto_project = 1
" 
" " Enable autoimport
" let g:pymode_rope_enable_autoimport = 1
" 
" " Auto generate global cache
" let g:pymode_rope_autoimport_generate = 1
" let g:pymode_rope_autoimport_underlineds = 0
" let g:pymode_rope_codeassist_maxfixes = 10
" let g:pymode_rope_sorted_completions = 1
" let g:pymode_rope_extended_complete = 1
" let g:pymode_rope_autoimport_modules = ["os","shutil","datetime", "sys"]
" let g:pymode_rope_confirm_saving = 1
" let g:pymode_rope_global_prefix = "<C-x>p"
" let g:pymode_rope_local_prefix = "<C-c>r"
" let g:pymode_rope_vim_completion = 1
" let g:pymode_rope_guess_project = 1
" let g:pymode_rope_goto_def_newwin = ""
" let g:pymode_rope_always_show_complete_menu = 1
" let g:pymode_rope_short_prefix = "<C-x>t"
" 
" " Documentation
" " let g:pymode_doc = 1
" " let g:pymode_doc_key = 'K'
" 
" "Linting
" let g:pymode_lint = 1
" " let g:pymode_lint_checker = "pep8,pyflakes"
" " Auto check on save
" let g:pymode_lint_write = 1
" " Check while typing
" let g:pymode_lint_onfly = 0
" " Don't open the error window
" let g:pymode_lint_cwindow = 0
" " Show an error message at the cursor
" let g:pymode_lint_message = 1
" " I prefer a blank line at the end of files
" let g:pymode_lint_ignore = "W391"
" 
" 
" " Support virtualenv
" let g:pymode_virtualenv = 1
" 
" " Enable breakpoints plugin
" let g:pymode_breakpoint = 1
" let g:pymode_breakpoint_key = '<leader>b'
" 
" " syntax highlighting
" let g:pymode_syntax = 1
" let g:pymode_syntax_all = 1
" let g:pymode_syntax_indent_errors = g:pymode_syntax_all
" let g:pymode_syntax_space_errors = g:pymode_syntax_all
" 
" " Don't autofold code
" let g:pymode_folding = 0
" 
" " Load rope plugin
" let g:pymode_rope = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Python Jedi plugin for better autocompletion
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if python_version >= 205
    Plug 'davidhalter/jedi-vim'
endif

" I find buffer to be quite convenient, but tabs or splits are also an option
let g:jedi#use_tabs_not_buffers = 0
let g:jedi#use_splits_not_buffers = 1

" Shortcuts
let g:jedi#goto_assignments_command = "<leader>g"
let g:jedi#goto_definitions_command = "<leader>d"
let g:jedi#documentation_command = "K"
let g:jedi#usages_command = "<leader>n"
let g:jedi#completions_command = "<C-Space>"
let g:jedi#rename_command = "<leader>r"
let g:jedi#show_call_signatures = "2"
let g:jedi#smart_auto_mappings = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Really nice color schemes for 256 colors shell
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'desert256.vim'
Plug 'oceandeep'
Plug 'vim-scripts/xorium.vim'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize Plug
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#end()

if iCanHazPlug == 0
    PlugUpdate
endif



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" How many lines of history to remember
set history=10000 
" enable error files and error jumping
set cf 
" support all three, in this order
set ffs=unix,dos,mac 
" make sure it can save viminfo
set viminfo+=! 
" none of these should be word dividers, so make them not be
set isk+=_,$,@,%,# 
" leave my cursor where it was
set nosol 
" Enable modelines (NOTE! this is potentially dangerous as it will also load
" settings from files you might not trust. Beware of this if you regularly
" open files from untrusted sources
set modeline
" Allow modelines to be read from the first/last 4 lines of a file
set modelines=4
" Enable secure mode with exrc (NOTE! this is potentially dangerous as it will
" also load settings from files in your current working directory from files
" you might not trust. Beware of this if you regularly open directories from
" untrusted sources
" set exrc
set secure
" Lower the timeout for mappings, they are annoyingly slow otherwise
set timeout timeoutlen=5000 ttimeoutlen=50
" Write all files on `make`
set autowrite
set autowriteall

au FocusLost * silent! wa

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Files/Backups
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" No backup files
set nobackup 
" What should be saved during sessions being saved
set sessionoptions+=globals 
" What should be saved during sessions being saved
set sessionoptions+=localoptions 
" What should be saved during sessions being saved
set sessionoptions+=resize 
" What should be saved during sessions being saved
set sessionoptions+=winpos 
" Enable global undo even after closing Vim
if version >= 703
    set undofile
    set undodir=~/.vim/undo
    set undolevels=10000

    call system('mkdir ' . expand('~/.vim/undo'))
endif
" Tell vim to remember certain things when we exit
" '1000 :  marks will be remembered for up to 10 previously edited files
" "100  :  will save up to 100 lines for each register
" :1000 :  up to 20 lines of command-line history will be remembered
" %     :  saves and restores the buffer list
" n...  :  where to save the viminfo files
if !has('nvim')
    set viminfo='1000,\"100,:1000,%,n~/.viminfo
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim UI
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" space it out a little more (easier to read)
set lsp=0 
" turn on wild menu
set wildmenu 
" turn on wild menu in special format (long format)
set wildmode=list:full 
" ignore formats
set wildignore=*.dll,*.o,*.obj,*.bak,*.exe,*.pyo,*.pyc,*.swp,*.jpg,*.gif,*.png 
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*\\tmp\\*,*.swp,*.zip,*.exe,*.dll
if version >= 703
    set wildignorecase
endif
if version >= 704
    set fileignorecase 
endif
" Always show current positions along the bottom 
set ruler 
" the command bar is 1 high
set cmdheight=1 
" turn on line numbers
set number 
" do not redraw while running macros (much faster) (LazyRedraw)
set lz 
" you can change buffer without saving
set hid 
" make backspace work normal
set backspace=2 
" allow backspacing over everything in insert mode
set bs=indent,eol,start     
" backspace and cursor keys wrap to
set whichwrap+=<,>,h,l  
" use mouse for help but not everywhere
set mouse=h

" shortens messages to avoid 'press a key' prompt 
set shortmess=atI 
" tell us when anything is changed via :...
set report=0 
" don't make noise
set noerrorbells 
" we do what to show tabs, to ensure we get them out of my files
set nolist 
" show tabs and trailing whitespace
set listchars=tab:\ \ ,trail:·,eol:¬,nbsp:_

" add the pretty line at 80 characters
if version >= 703
    set colorcolumn=80
    hi ColorColumn ctermbg=52
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Visual Cues
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" show matching brackets
set showmatch 
" how many tenths of a second to blink matching brackets for
set matchtime=2 
" do not highlight searched for phrases
set nohlsearch 
" BUT do highlight as you type you search phrase
set noincsearch 
" Keep 5 lines (top/bottom) for scope
set so=5 
" don't blink
set visualbell 
" always show the status line
set laststatus=2 

" statusline example: ~\myfile[+] [FORMAT=format] [TYPE=type] [ASCII=000] 
" [HEX=00] [POS=0000,0000][00%] [LEN=000]
" set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ 
" [HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
" Pretty status line
set statusline=   " clear the statusline for when vimrc is reloaded
set statusline+=%-3.3n\                      " buffer number
set statusline+=%f\                          " file name
set statusline+=%h%m%r%w                     " flags
" set statusline+=[%{strlen(&ft)?&ft:'none'},  " filetype
" set statusline+=%{strlen(&fenc)?&fenc:&enc}, " encoding
" set statusline+=%{&fileformat}]              " file format
set statusline+=%=                           " right align
set statusline+=%{synIDattr(synID(line('.'),col('.'),1),'name')}\  " highlight
set statusline+=%b,0x%-8B\                   " current char
set statusline+=%-14.(%l,%c%V%)\ %<%P        " offset

" Make the autocomplete menu a pretty color
highlight Pmenu ctermbg=52 ctermfg=lightyellow

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Indent Related
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" autoindent (filetype indenting instead)
set ai 
" smartindent (filetype indenting instead)
set nosi 
" do c-style indenting
set cindent 
" unify
set softtabstop=4 
" unify
set shiftwidth=4 
" real tabs should be 4, but they will show with set list on
set tabstop=4 
" but above all -- follow the conventions laid before us
set copyindent 

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Text Formatting/Layout
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" See Help (complex)
set fo=tcrq 
" when at 3 spaces, and I hit > ... go to 4, not 5
set shiftround 
" no real tabs!
set expandtab 
" do not wrap line
set nowrap 
" but above all -- follow the conventions laid before us
set preserveindent 
" case sensitive by default
set noignorecase 
" if there are caps, go case-sensitive
set smartcase 
" improve the way autocomplete works
set completeopt=menu,longest,preview 
" set cursorcolumn " show the current column

" Make sure # doesn't start at the beginning of the line
set cinkeys-=0#
set indentkeys-=0#

" Don't scroll when splitting windows
nnoremap <C-W>s Hmx`` \|:split<CR>`xzt``

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Folding
"    Enable folding, but by default make it act like folding is 
"    off, because folding is annoying in anything but a few rare 
"    cases
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn on folding
set foldenable 
" Fold C style code
set foldmarker={,} 
" Fold on the marker 
set foldmethod=marker 
" Don't autofold anything (but I can still fold manually)
set foldlevel=100 
" don't open folds when you search into them
set foldopen-=search 
" don't open folds when you undo stuff
set foldopen-=undo 

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CTags
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Location of ctags
let Tlist_Ctags_Cmd = 'ctags' 
" order by 
let Tlist_Sort_Type = "name" 
" split to the right side of the screen
let Tlist_Use_Right_Window = 1 
" show small meny
let Tlist_Compact_Format = 1 
" if you are the last, kill yourself
let Tlist_Exist_OnlyWindow = 1 
" Do not close tags for other files
let Tlist_File_Fold_Auto_Close = 0 
" Do show folding tree
let Tlist_Enable_Fold_Column = 1 
" 50 cols wide, so I can (almost always) read my functions
let Tlist_WinWidth = 50 
" don't show variables in php
let tlist_php_settings = 'php;c:class;d:constant;f:function' 
" just functions and subs
let tlist_aspvbs_settings = 'asp;f:function;s:sub' 
" just functions and classes
let tlist_aspjscript_settings = 'asp;f:function;c:class' 
" just functions and classes
let tlist_vb_settings = 'asp;f:function;c:class' 

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Matchit
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let b:match_ignorecase = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Perl
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let perl_extended_vars=1 " highlight advanced perl vars inside strings

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Change paging overlap amount from 2 to 5 (+3)
" if you swapped C-y and C-e, and set them to 2, it would 
" remove any overlap between pages
nnoremap <C-f> <C-f>3<C-y> "  Make overlap 3 extra on control-f
nnoremap <C-b> <C-b>3<C-e> "  Make overlap 3 extra on control-b
" Add the current date in yyyy-mm-dd format
nnoremap <F5> "=strftime("%F")<CR>P
inoremap <F5> <C-R>=strftime("%F")<CR>
" Insert the current filename
nnoremap <F6> "=expand("%:t:r")<CR>P
inoremap <F6> <C-R>=expand("%:t:r")<CR>
" Going to matching braces
inoremap } }<Left><c-o>%<c-o>:sleep 500m<CR><c-o>%<c-o>a
inoremap ] ]<Left><c-o>%<c-o>:sleep 500m<CR><c-o>%<c-o>a
inoremap ) )<Left><c-o>%<c-o>:sleep 500m<CR><c-o>%<c-o>a

" Disable Ex mode
nnoremap Q <nop>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Map filetypes to get proper highlighting
augroup filetypedetect
    au BufNewFile,BufRead /usr/local/etc/apache22/* setf apache
    au BufNewFile,BufRead /etc/supervisor/* setf supervisor
    au BufNewFile,BufRead /usr/local/etc/nginx/* setf nginx
    au BufNewFile,BufRead */templates/*.html setf jinja
    au BufNewFile,BufRead *.pig set filetype=pig syntax=pig 
    au BufNewFile,BufRead *.qvpp set filetype=html
augroup END

autocmd Filetype python setlocal suffixesadd=.py

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable 256 color support when available
if ((&term == 'xterm-256color') || (&term == 'screen-256color' || &term == 'nvim'))
    set t_Co=256
    set t_Sb=[4%dm
    set t_Sf=[3%dm
    silent! colo desert256
    if &diff
        colorscheme xorium
    endif
else
    silent! colo desert
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Save and restore the cursor
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! ResCur()
  if line("'\"") <= line("$")
    normal! g`"
    return 1
  endif
endfunction

augroup resCur
  autocmd!
  autocmd BufWinEnter * call ResCur()
augroup END

" For weird PATH stuff on OS X either enable this, or make the path_helper not
" executable anymore: sudo chmod ugo-x /usr/libexec/path_helper
" set shell=/bin/bash

" Fixing crontab issues on OS X
au BufEnter /private/tmp/crontab.* setl backupcopy=yes

" Make needed directories when writing files
function! s:MkNonExDir(file, buf)
    if empty(getbufvar(a:buf, '&buftype')) && a:file!~#'\v^\w+\:\/'
        let dir=fnamemodify(a:file, ':h')
        if !isdirectory(dir)
            call mkdir(dir, 'p')
        endif
    endif
endfunction
augroup BWCCreateDir
    autocmd!
    autocmd BufWritePre * :call s:MkNonExDir(expand('<afile>'), +expand('<abuf>'))
augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" After loading the bundles we can enable the plugins again
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" load filetype plugins and indent settings
filetype plugin indent on 
" autocmd BufRead *.py silent PyFlake|silent redraw
" syntax highlighting on
syntax on 

" Full recalculation function
autocmd VimEnter * call UpdateBufferCount() 

if !exists('*UpdateBufferCount')
    function UpdateBufferCount() 
        let buffers = range(1, bufnr('$')) 
        call filter(buffers, 'buflisted(v:val)') 
        let g:buffer_count = len(buffers) 
    endfunction 
endif

" Update count
call UpdateBufferCount()

" Increment and decrement when needed
autocmd BufAdd * let g:buffer_count += 1 
autocmd BufDelete * let g:buffer_count -= 1 

set rulerformat+=%n/%{g:buffer_count}

" auto-reload vimrc on save
augroup reload_vimrc " {
  autocmd!
  autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END " }
