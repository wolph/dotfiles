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
        if executable('curl')
            silent !curl -Lqo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        else
            silent !curl -qO ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        endif

        source ~/.vim/autoload/plug.vim
    let iCanHazPlug=0
endif

let g:plug_threads = 16

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Make sure neovim uses a stable Python host
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has('nvim') && executable('python3')
    let g:python3_host_prog = exepath('python3')
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Automatically fix common typos
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
iabbrev improt import
iabbrev teh the

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Load and install the Plugs using Plug
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin(expand('~/.vim/bundle'))
" Tree like file browser
Plug 'preservim/nerdtree'
" A Git wrapper so awesome, it should be illegal
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-repeat'
Plug 'lepture/vim-jinja'
Plug 'chr4/nginx.vim'

Plug 'Vimjas/vim-python-pep8-indent'
Plug 'AndrewRadev/linediff.vim'

Plug 'junegunn/vim-easy-align'
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

Plug 'tomtom/tcomment_vim'
vmap / gc<cr>

Plug 'junegunn/vim-peekaboo'

if has("nvim")
    tnoremap <C-w><C-w> <C-\><C-n><C-w><C-w>
    tnoremap <C-w>h <C-\><C-n><C-w>h
    tnoremap <C-w>j <C-\><C-n><C-w>j
    tnoremap <C-w>k <C-\><C-n><C-w>k
    tnoremap <C-w>l <C-\><C-n><C-w>l
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Split one-liners or join multi-line statements
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'AndrewRadev/splitjoin.vim'
nmap <Leader>j :SplitjoinJoin<cr>
nmap <Leader>s :SplitjoinSplit<cr>
nmap gj :SplitjoinSplit<cr>
nmap gs :SplitjoinJoin<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Toggle between values such as true/false
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'AndrewRadev/switch.vim'
let g:switch_mapping = '"'
autocmd FileType python let b:switch_custom_definitions =
            \ [
            \ {'"': '''',},
            \ ]

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim indent guides
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'nathanaelkane/vim-indent-guides'
let g:indent_guides_enable_on_vim_startup = 1
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  ctermbg=235
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=234


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Fuzzy finder (fzf)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find fzf wherever this machine has it (Apple Silicon brew, Intel brew,
" or the git install); fall back to CtrlP when there is no fzf at all.
let s:fzf_dir = ''
for s:dir in ['/opt/homebrew/opt/fzf', '/usr/local/opt/fzf', expand('~/.fzf')]
    if isdirectory(s:dir)
        let s:fzf_dir = s:dir
        break
    endif
endfor
if s:fzf_dir != ''
    execute 'Plug ' . string(s:fzf_dir)

    Plug 'junegunn/fzf.vim'

    " This is the default extra key bindings
    let g:fzf_action = {
        \ 'enter': 'rightbelow split',
        \ 'ctrl-e': 'edit',
        \ 'ctrl-t': 'tab split',
        \ 'ctrl-x': 'rightbelow split',
        \ 'ctrl-v': 'rightbelow vsplit' }

    let g:fzf_command_prefix = ''

    " Default fzf layout
    " - down / up / left / right
    let g:fzf_layout = { 'down': '~70%' }

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
    " imap <c-x><c-o> <plug>(fzf-complete-line)
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
" Ansible Vim syntax
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'chase/vim-ansible-yaml'
let g:ansible_options = {'ignore_blank_lines': 0, 'documentation_mapping': '<C-K>'}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Gundo/Mundo, the holy grail in undos
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'simnalamburt/vim-mundo'
nnoremap U :silent MundoToggle<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Snippets
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Rainbow parenthesis
Plug 'luochen1990/rainbow'
let g:rainbow_active=1

command! -nargs=1 Silent
\ | execute ':silent !'.<q-args>
\ | execute ':redraw!'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable the system clipboard if available
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has("clipboard")
  set clipboard=unnamed " copy to the system clipboardA
  set mouse= 

  if has("unnamedplus") " X11 support
    set clipboard+=unnamedplus
  endif
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Surround text/selection with tags
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'tpope/vim-surround'

autocmd FileType rst let g:surround_{char2nr(':')} = ":\1command\1:`\r`"
autocmd FileType rst vmap m S:math<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" reStructuedText in Vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
augroup filetypedetect
    au BufNewFile,BufRead *.rst set suffixesadd+=.rst
    au BufNewFile,BufRead *.rst set ft=doctest
augroup END
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Supertab so we can <Tab> for autocompletion
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'ervandew/supertab'

let g:SuperTabDefaultCompletionType = "context"
let g:SuperTabContextDefaultCompletionType = "<c-x><c-o>"

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Really nice color schemes for 256 colors shell
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'vim-scripts/desert256.vim'
Plug 'vim-scripts/xorium.vim'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize Plug
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#end()

if iCanHazPlug == 0
    PlugInstall
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
set exrc
set secure
" Lower the timeout for mappings, they are annoyingly slow otherwise
set timeout timeoutlen=5000 ttimeoutlen=50
" Write all files on `make` disabled because it causes automatic writes when
" backgrounding neovim
" set autowrite
" set autowriteall

" au FocusLost * silent! wa

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
set shortmess=atIF 
" tell us when anything is changed via :...
set report=0 
" don't make noise
set noerrorbells 
" we do what to show tabs, to ensure we get them out of my files
set nolist 
" show tabs and trailing whitespace
set listchars=tab:>-,trail:-

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
" Keep 15 lines (top/bottom) for scope (when searching)
set so=15 
" don't blink
set visualbell 
" always show the status line
set laststatus=2 

" Pretty status line
set statusline=   " clear the statusline for when vimrc is reloaded
set statusline+=%-3.3n\                      " buffer number
set statusline+=%f\                          " file name
set statusline+=%h%m%r%w                     " flags
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

" when incrementing numbers, don't use octal mode
set nrformats-=octal

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

nmap < :foldclose<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Change paging overlap amount from 2 to 5 (+3)
" if you swapped C-y and C-e, and set them to 2, it would 
" remove any overlap between pages
" Make overlap 3 extra on control-f and control-b
nnoremap <C-f> <C-f>3<C-y>
nnoremap <C-b> <C-b>3<C-e>
" Add the current date in yyyy-mm-dd format
nnoremap <F5> "=strftime("%F")<CR>P
inoremap <F5> <C-R>=strftime("%F")<CR>
" Insert the current filename
nnoremap <F6> "=expand("%:t:r")<CR>P
inoremap <F6> <C-R>=expand("%:t:r")<CR>

" Disable Ex mode
nnoremap Q <nop>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Map filetypes to get proper highlighting
augroup filetypedetect
    au BufNewFile,BufRead */apache/* setf apache
    au BufNewFile,BufRead */nginx/* setf nginx
    au BufNewFile,BufRead *.html setf jinja
    au BufNewFile,BufRead *.qvpp set filetype=html
augroup END

autocmd Filetype python setlocal suffixesadd=.py
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable 256 color support when available
if has('nvim')
    set termguicolors
    silent! colo desert
elseif (&term == 'xterm-256color') || (&term == 'screen-256color')
    set t_Co=256
    set t_Sb=[4%dm
    set t_Sf=[3%dm
    silent! colo desert256
    if &diff
        silent! colorscheme xorium
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
" Save and restore the session
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fu! SaveSess()
    execute 'mksession! ' . getcwd() . '/.session.vim'
endfunction

fu! RestoreSess()
if filereadable(getcwd() . '/.session.vim')
    execute 'so ' . getcwd() . '/.session.vim'
    if bufexists(1)
        for l in range(1, bufnr('$'))
            if bufwinnr(l) == -1
                exec 'sbuffer ' . l
            endif
        endfor
    endif
endif
endfunction

" autocmd VimLeave * call SaveSess()
autocmd VimEnter * nested call RestoreSess()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" After loading the bundles we can enable the plugins again
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" load filetype plugins and indent settings
filetype plugin indent on 
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

command! CloseHiddenBuffers call s:CloseHiddenBuffers()
function! s:CloseHiddenBuffers()
  let open_buffers = []

  for i in range(tabpagenr('$'))
    call extend(open_buffers, tabpagebuflist(i + 1))
  endfor

  for num in range(1, bufnr("$") + 1)
    if buflisted(num) && index(open_buffers, num) == -1
      exec "bdelete ".num
    endif
  endfor
endfunction

" auto-reload vimrc on save
if has ('autocmd') " Remain compatible with earlier versions
 augroup vimrc     " Source vim configuration upon save
    autocmd! BufWritePost ~/.vimrc source % | redraw
    autocmd! BufWritePost ~/.gvimrc if has('gui_running') | source % | endif | redraw
  augroup END
endif " has autocmd
