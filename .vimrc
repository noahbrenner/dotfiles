setglobal nocompatible

" TODO Check whether bufname(1) ends with .git/COMMIT_EDITMSG and exit early if so
" echom "Filetype at startup:" bufname(1)
" finish
" Also take a look at: https://til.hashrocket.com/posts/c265634512-vim-startup-time-profiling

let $MYVIMHOME=fnameescape(expand('<sfile>:p:h'))

" Alternates from: https://github.com/justinmk/config/blob/master/.vimrc
let s:is_gui = has('gui_running') || strlen(&term) is 0 || &term is? 'builtin_gui'
let s:is_cygwin = has('win32unix') || has('win64unix')
let s:is_windows = has('win32') || has('win64')

if s:is_gui
  setglobal guioptions+=c " Use console dialogues instead of popup dialogues

  " This must be set before running `:syntax on` or `:fileype on`
  setglobal guioptions+=M " Don't source "$VIMRUNTIME/menu.vim"

  setglobal guioptions-=m " Don't display menu
  setglobal guioptions-=g " Don't grey menu items (irrelevant)
  setglobal guioptions-=t " Don't use tearoff menues (irrelevant)
  setglobal guioptions-=T " Don't display toolbar
  setglobal guioptions-=r " Don't always show right-hand scrollbar
  setglobal guioptions-=L " Don't show left-hand scrollbar when there's a vertical split
  " Windows: ecM
  " Linux:   aeicM
endif

" Set window size when starting GUI
if s:is_gui && has('vim_starting')
  " Define the function that does the resizing
  function! s:setwinsize()
    let l:posx = getwinposx() " Get x position before resizing

    setglobal lines=999 " Use full screen height
    setglobal columns=999 " Start with full screen width

    let l:posy = getwinposy() " Get y position potentially adjusted by resizing

    " Use full screen width when diffing *multiple* files
    if &diff && argc() > 1
      setglobal columns=999

    " Otherwise, set columns based on screen width
    elseif &columns < 160
      setglobal columns=80
    elseif &columns > 180
      setglobal columns=90
    else
      let &columns = &columns / 2
    endif

    " Put the window back where the windowing system first put it (horizontally)
    execute "winpos" l:posx l:posy
  endfunction

  " TODO Always call the function immediately; On Linux, set lines=99 in autocmd
  " Call and/or schedule calling the function
  if s:is_windows
    " Windows can run this right away and avoid a flash of the large window size
    call s:setwinsize()
  else
    " Run at GUIEnter so that &columns will be limited by screen size
    autocmd GUIEnter * call s:setwinsize()
  endif
endif


let mapleader = ","
let maplocalleader = "\\"


if s:is_windows
  " Add some UNIX-y tools to PATH
  let $PATH .= ';C:/Program Files/Git/mingw32/bin'
endif

" Define script location for "vim-plug"
" - On Windows, we'll put the 'autoload/' directory alongside .vimrc
" - Otherwise, we'll put it in the home directory, under '.vim/'
let s:plug_script = s:is_windows || s:is_cygwin
      \ ? $MYVIMHOME . '\autoload\plug.vim'
      \ : $MYVIMHOME . '/.vim/autoload/plug.vim'

if filereadable(s:plug_script)
  " vim-plug is already installed, nothing to see here...
  unlet s:plug_script
elseif $USER !=# 'root'
  let s:plug_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

  " If vim-plug isn't loaded, download and source it. This is expected to run
  " only the first time VIM is run after a new OS install.
  execute 'silent !curl --create-dirs -Lo "' . s:plug_script . '" ' . s:plug_url
  execute 'source ' . s:plug_script

  unlet s:plug_url
  unlet s:plug_script
  let s:is_fresh_plug_install = 1
endif

let g:plug_window = 'topleft new'

call plug#begin()

" GENERIC TOOLS:
Plug 'junegunn/vim-plug' " Included here so that the help file is installed
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-characterize' " Show more character info with `ga`
Plug 'editorconfig/editorconfig-vim'
  " Ignore contents of .git/ directories
  let g:EditorConfig_exclude_patterns = ['.*[\\/]\.git[\\/].*']
" TODO https://github.com/tpope/vim-eunuch " Convenient shell wrappers like :Rename
Plug 'tpope/vim-dispatch'

Plug 'nathanaelkane/vim-indent-guides'
  let g:indent_guides_color_change_percent = 25
  let g:indent_guides_guide_size = 1

" SYNTAX HIGHLIGHTING AND BEHAVIOR:
Plug 'kchmck/vim-coffee-script', {'for': 'coffee'}
Plug 'othree/html5.vim'
Plug 'pangloss/vim-javascript', {'for': 'javascript'}
Plug 'glench/vim-jinja2-syntax', {'for': ['jinja.html', 'jinja']} " Also for Nunjucks
Plug 'gisraptor/vim-lilypond-integrator', {'for': 'lilypond'}
Plug 'mustache/vim-mustache-handlebars'
Plug 'vim-pandoc/vim-pandoc', {'for': 'pandoc'}
Plug 'vim-pandoc/vim-pandoc-syntax', {'for': 'pandoc'}
Plug 'digitaltoad/vim-pug', {'for': 'pug'}

Plug 'mattn/emmet-vim' " Expand abbreviations (mainly HTML)
  let g:emmet_install_only_plug = 1 " Don't create default keymappings
  if s:is_gui
    nmap <c-space> <plug>(emmet-expand-abbr)
    imap <c-space> <plug>(emmet-expand-abbr)
  else
    " These mean the same as above, but they work in the terminal
    nmap <c-@> <plug>(emmet-expand-abbr)
    imap <c-@> <plug>(emmet-expand-abbr)
  endif
  nmap <Leader><c-n> <plug>(emmet-move-next)
  imap <Leader><c-n> <plug>(emmet-move-next)
  nmap <Leader><c-p> <plug>(emmet-move-prev)
  imap <Leader><c-p> <plug>(emmet-move-prev)
  " TODO: Put these in an autocmd? (html/js/jsx/tsx/md/etc.)
  nmap <Leader>is <plug>(emmet-image-size)
  imap <Leader>is <plug>(emmet-image-size)
  nmap <Leader>a <plug>(emmet-anchorize-url)
  imap <Leader>a <plug>(emmet-anchorize-url)

" TODO Validate HTML - https://stackoverflow.com/questions/5237275/how-can-i-validate-html5-directly-in-vim

"Plug 'nikvdp/ejs-syntax', {'for': ['html.ejs', 'ejs']}
Plug 'briancollins/vim-jst', {'for': ['*.jst', 'jst.*', 'jst']} " .ejs
  augroup detect_ejs
    " If ejs isn't the last file extension, we can use the detected filetype
    " TODO This might only work when .vimrc is in the default location. If I
    " find that to be true, remove the ternary expression, just using '&ft'.
    autocmd! BufRead,BufNewFile *.ejs.* let &filetype = &filetype
          \ ? 'jst.' . &filetype
          \ : 'jst.' . expand('%:e')
    " Otherwise, we'll use the preceding extention as the filetype (not perfect)
    autocmd! BufRead,BufNewFile *.*.ejs let &filetype = 'jst.' . expand('%:r:e')
  augroup END

Plug 'maxmellon/vim-jsx-pretty'

Plug 'plasticboy/vim-markdown', {'for': 'markdown'}
  let g:vim_markdown_folding_style_pythonic = 1
  let g:vim_markdown_frontmatter = 1
  let g:vim_markdown_toc_autofit = 1

" TODO Plug 'https://github.com/quramy/tsuquyomi' " TypeScript IDE behavior for Vim
Plug 'HerringtonDarkholme/yats.vim', {'for': ['typescript', 'typescript.tsx']}

" SYNTAX CHECKERS:
let g:ale_completion_enabled = 1
Plug 'w0rp/ale'
  let g:ale_linters = {
        \ 'javascript': [],
        \ 'markdown': [],
        \ 'python': ['pycodestyle', 'flake8'],
        \ }
  let g:ale_fixers = {
        \ 'css': ['prettier'],
        \ 'html': ['prettier'],
        \ 'javascript': ['prettier'],
        \ 'json': ['prettier'],
        \ 'markdown': ['prettier'],
        \ 'typescript': ['prettier'],
        \ 'typescriptreact': ['prettier'],
        \ }

  " Configure message formats
  let g:ale_echo_msg_format = "[%linter%] %code: %%s"

  " Define key mappings
  nmap <silent> <c-k> <plug>(ale_previous_wrap)
  nmap <silent> <c-j> <plug>(ale_next_wrap)

  " Configure status line format
  let &g:statusline = "%q" " [Quickfix List], [Location List] or empty
  let &g:statusline .= "%w" " Preview window flag [Preview]
  let &g:statusline .= "%<%f\ " " Path to file, truncated on the left if needed
  let &g:statusline .= "%h%m%r" " Help, modified, and readonly flags
  let &g:statusline .= "%=" " Separation between left- and right-aligned items
  " Note: %c = column number in bytes; %v = virtual column number
  let &g:statusline .= "%-8.(%l,%c%)" " Left-justify line & col number w/ minwidth of 8
  let &g:statusline .= "\ %P" " Percentage through file (or Top/Bot/All)

call plug#end()

" Might use one of these for Python at some point (linked from Syntastic README):
" https://github.com/davidhalter/jedi-vim
" https://github.com/python-mode/python-mode

if exists('s:is_fresh_plug_install')
  PlugInstall
  unlet s:is_fresh_plug_install
endif

if has('vim_starting')
  " Set this only when starting up so matches aren't shown again when reloading .vimrc
  setglobal hlsearch

  " Jump to last known cursor position when opening a file (from vimrc_example.vim)
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   execute "normal! g`\"" |
    \ endif

  if &encoding is# 'latin1'
    setglobal encoding=utf-8
  endif
endif

" These settings are for the plugin: https://github.com/hdima/python-syntax
let g:SimpleJsIndenter_BriefMode = 1 " Only indent 1 shiftwidth at a time
"let python_version_2 = 1
let python_highlight_all = 1

" Beautify Messy Files:
function! Beautify()
  if count(['html', 'css', 'javascript', 'json'], &filetype)
    let type = count(['javascript', 'json'], &filetype) ? 'js' : &filetype
    let indent = &filetype is# 'javascript' ? 4 : 2
    execute "%! js-beautify --indent-size" indent "--type" type

  elseif &filetype is# 'diff'
    " Shorten headings for each diffed file to show only one line. Includes the file name.
    %s/\v^diff --git \zsa\/(.*) b\/.*%(\n.*){3}/\1/
    " Set cursor to start of file and highlight diffed filenames
    call cursor(1, 1)
    let @/ = '^diff.\{-}\zs[^/ ]*$'
    redraw

  else
    echo "No beautify settings for file type:" &filetype
  endif
endfunction

nnoremap <LocalLeader>b :call Beautify()<cr>

" Vim_Pandoc Configuration:
let g:pandoc#filetypes#pandoc_markdown = 0 " Don't use pandoc for all markdown extensions
let g:pandoc#formatting#equalprg = "" " Don't change default indenting
let g:pandoc#keyboard#use_default_mappings = 0 " Disable key mappings
let g:pandoc#syntax#conceal#blacklist = [
      \ "image",
      \ "subscript",
      \ "superscript",
      \ "codeblock_start",
      \ "codeblock_delim",
      \ "definition",
      \ "list",
      \ ]
      "\"newline",
let g:pandoc#syntax#conceal#cchar_overrides = {
      \ "newline": " ",
      \ "image": "i",
      \ }
let g:pandoc#syntax#codeblocks#embeds#langs = [
      \ "python",
      \ "javascript",
      \ ]

"syntax on
setglobal whichwrap+=[,] " Arrow keys wrap around lines in insert and replace modes
setglobal cpoptions+=J " A sentence object ends with 2 spaces

" If I want to mark eol at some point, here are some good options: $ ¬ ⏎▸
" Set by vim-sensible: listchars=tab:> ,trail:-,extends:>,precedes:<,nbsp:+
setglobal listchars=tab:├─,trail:·,nbsp:⎵,extends:>,precedes:<
set list " 'list' is local, but we also set it globally to work for new windows

if has('vim_starting')
  " Set swapfile directory
  let s:swapfile_dir = '~/.swapfiles'
  execute 'setglobal directory^=' . s:swapfile_dir . '//'

  " Create the swapfile directory if it doesn't exist
  if !isdirectory(expand(s:swapfile_dir))
    if exists('*mkdir')
      " Reference: https://stackoverflow.com/questions/1549263/how-can-i-create-a-folder-if-it-doesnt-exist-from-vimrc/8462159
      call mkdir(expand(s:swapfile_dir), 'p', 0700)
    else
      echomsg "Vim can't make directories. Please create: " . s:swapfile_dir
    endif
  endif
  unlet s:swapfile_dir

  setglobal mouse=a " Enable the mouse when running via terminal
  setglobal cryptmethod=blowfish2
  setglobal backupcopy=yes " https://github.com/parcel-bundler/parcel/issues/221
  "setglobal selection=old "TODO find out why this was exclusive. Check :behave command.

  colorscheme pablo
  highlight Folded ctermfg=LightCyan ctermbg=DarkBlue guibg=#333333
  highlight LineNr guifg=Red guibg=#202020
  highlight Special guifg=#2222ff
  highlight SpellBad ctermbg=DarkRed
  " Switch the default coloring for active vs. inactive status lines
  highlight StatusLine ctermfg=NONE ctermbg=NONE cterm=reverse
  highlight StatusLineNC cterm=NONE ctermfg=11 ctermbg=12

  setglobal fileformats=unix,dos,mac
  setglobal ignorecase
  setglobal smartcase
  setglobal showcmd
  " These are local options, but we set global as well to affect windows opened later
  set linebreak
  set breakindent
  let &showbreak = '> '
  set foldmethod=marker
  set conceallevel=2

  " Enable use of :Man command
  runtime ftplugin/man.vim

  " TODO Could look into NerdTree or https://github.com/justinmk/vim-dirvish
  let g:netrw_banner = 0 " Hide banner
  let g:netrw_fastbrowse = 0 " https://github.com/tpope/vim-vinegar/issues/13
  let g:netrw_liststyle = 3 " Tree view
  let g:netrw_winsize = 30 " This is a percentage of the available space
endif

" TODO make function(s) to change fonts/sizes
"setglobal guifont=Courier_New:h9 " The font used for :hardcopy (but different size)
"setglobal guifont=Dina:h9:cANSI
" Small: Dina:h6 (best so far), DejaVu_Sans_Mono:w4:h7
if s:is_windows
  " setglobal guifont=Terminus:h11
  setglobal guifont=Terminus:h9  " TODO make a good way to switch
  " For some reason, this doesn't have all of the characters that it does on Linux
  " (particularly, music symbols), but it does have more than Terminus.
  " setglobal guifont=DejaVu_Sans_Mono:8
  " This one might be a decent middle ground
  " setglobal guifont=Hack:h8
else
  setglobal guifont=DejaVu\ Sans\ Mono\ 9  " 10 ~= Terminus:h11, 8 ~= Terminus:h9
endif

" Display `git diff` output if vim is started as `gvimdiff` with no arguments
if has('vim_starting') && s:is_gui && &diff && argc() ==# 0
  function! s:init_git_diff()
    " Reduce font size so we can see more lines at a time
    let &guifont = s:is_windows
          \ ? 'Dina:h7'
          \ : 'DejaVu Sans Mono 7'

    " Use the full screen height again, now that we've reduced the font size
    setglobal lines=999

    " Adjust highlighting
    diffoff
    setlocal filetype=diff

    " Prevent accidental writing of the file
    setlocal buftype=nofile
    setlocal noswapfile

    " Set the filename so that the window is easier to identify
    file DIFF

    " Replace buffer contents with diff output. The (empty) content of the
    " buffer is passed to git's stdin, but git doesn't care.
    silent %!git diff
  endfunction

  autocmd VimEnter * call s:setwinsize() | call s:init_git_diff()
endif

" Edit VIMRC:
nnoremap <Leader>ev :split $MYVIMRC<cr>
nnoremap <Leader><Leader>ev :tabedit $MYVIMRC<cr>
nnoremap <Leader>sv :source $MYVIMRC \| doautocmd FileType<cr>
" Execute Current Line: " Good for ex commands like: !pandoc %:p
nnoremap <leader>el :execute getline(".")<cr>
" Switch Windows:
nnoremap <Leader>j <c-w>j
nnoremap <silent> <Leader><Leader>j <c-w>j:resize<cr>
nnoremap <Leader>k <c-w>k
nnoremap <silent> <Leader><Leader>k <c-w>k:resize<cr>
nnoremap <Leader>h <c-w>h
nnoremap <Leader>l <c-w>l
" Go To Beginning Or End Of Line:
nnoremap H ^
nnoremap L $
" Go To Top Or Bottom Of Window:
nnoremap <cr>k H
nnoremap <cr>j L

nnoremap <space> za
nnoremap <s-space> zA
inoremap jk <esc>
nnoremap - ddp
nnoremap _ ddkP
nnoremap <silent> `l :setlocal list!<cr>

" Easier completion mappings
inoremap <m-o> <c-x><c-o>
inoremap <c-f> <c-x><c-f>

" Completely clear the content saved in a named register
command! -nargs=1 ClearRegister call setreg('<args>', [])

augroup filetype_common_settings
  autocmd!

  " Helper function
  function! s:exec_for_filetypes(command, filetypes)
    if index(a:filetypes, &filetype) >= 0
      execute a:command
    endif
  endfunction

  " Define and set options based on filetype
  function! s:set_common_options()
    let l:indent_2 = [
          \ 'css',
          \ 'html',
          \ 'javascript',
          \ 'json',
          \ 'pug',
          \ 'tex',
          \ 'typescript',
          \ 'typescriptreact',
          \ 'vim',
          \ 'yaml',
          \ ]

    let l:indent_4 = [
          \ 'autohotkey',
          \ 'markdown',
          \ 'pandoc',
          \ 'python',
          \ ]

    let l:spell = [
          \ 'gitcommit',
          \ 'markdown',
          \ 'pandoc',
          \ ]

    call s:exec_for_filetypes('setlocal shiftwidth=2 expandtab', l:indent_2)
    call s:exec_for_filetypes('setlocal shiftwidth=4 expandtab', l:indent_4)
    call s:exec_for_filetypes('setlocal spell', l:spell)
  endfunction

  " Register a catch-all autocommand
  autocmd FileType * call s:set_common_options()
augroup END

" These must be set before a FileType autocmd would fire,
" so we'll just set them unconditionally
let g:is_bash=1
let g:sh_fold_enabled=5 " Fold: functions (1), if/do/for blocks (4)
augroup filetype_bash
  autocmd!
  autocmd FileType sh setlocal foldmethod=syntax
augroup END

augroup filetype_gitcommit
  autocmd!
  autocmd FileType gitcommit setlocal colorcolumn=+1 formatoptions-=l
augroup END

augroup filetype_html
  autocmd!
  autocmd FileType html setlocal foldmethod=indent foldlevel=99
  autocmd FileType html nnoremap <buffer> <LocalLeader>c I<!-- <esc>A --><esc>
  autocmd FileType html vnoremap <buffer> <LocalLeader>c <esc>`>a --><esc>`<i<!-- <esc>
  autocmd FileType html nnoremap <buffer> <LocalLeader>C :s/<!-- \(.*\) -->/\1/e \| noh<cr>
  autocmd FileType html inoremap <buffer> <LocalLeader>a <a href="
  autocmd FileType html vnoremap <buffer> <LocalLeader>a <esc>`>a</a><esc>`<i<a href=""><esc>F"i
  autocmd FileType html nnoremap <buffer> <LocalLeader>f Vatzf
  autocmd FileType html iabbrev <buffer> doc <!DOCTYPE html>
  " For dual filetypes (like jinja.html), make sure to load these settings
  autocmd FileType *.html doautocmd filetype_html FileType html
augroup END

augroup filetype_javascript
  autocmd!
  autocmd FileType javascript,typescript setlocal indentkeys+=0?,0<:>,0.
  autocmd FileType javascript,typescript setlocal number foldmethod=syntax
  autocmd FileType javascript,typescript nnoremap <buffer> <LocalLeader>c I// <esc>
  autocmd FileType javascript,typescript nnoremap <buffer> <LocalLeader>C :s,// ,, \| noh<cr>
  autocmd FileType javascript,typescript vnoremap <expr> <buffer> <LocalLeader>c mode() is# "v"
        \ ? "<esc>`>a */<esc>`<i/* <esc>"
        \ : "<esc>`>o*/<esc>`<O/*<esc>"
augroup END

augroup extension_njk " For Nunjucks templates, which use the same syntax as Jinja2
  autocmd!
  autocmd BufNewFile,BufReadPost,BufFilePost *.njk setlocal filetype=jinja.html
augroup END

augroup filetype_json
  autocmd!
  autocmd FileType json setlocal number conceallevel=0 foldmethod=syntax foldlevel=99
augroup END

augroup filetype_css
  autocmd!
  autocmd FileType css,scss setlocal foldmarker={,}
  autocmd FileType css,scss nnoremap <buffer> <LocalLeader>c I/*<esc>A*/<esc>
  autocmd FileType css,scss nnoremap <buffer> <LocalLeader>C :s,/\*\(.*\)\*/,\1,e \| noh<cr>
  autocmd FileType css,scss inoremap <buffer> { {<cr>}<esc>O
augroup END

augroup filetype_man
  autocmd!
  autocmd FileType man setlocal nolist
augroup END

augroup extension_ntxt
  autocmd!
  autocmd BufNewFile,BufReadPre,BufFilePre *.ntxt setglobal noshelltemp history=0 viminfo=""
  autocmd BufNewFile,BufReadPre,BufFilePre *.ntxt setlocal noswapfile noundofile nobackup
  autocmd BufNewFile,BufReadPre,BufFilePre *.ntxt filetype indent off
  autocmd BufNewFile,BufReadPre,BufFilePre *.ntxt nnoremap ZZ <nop>
  autocmd BufNewFile,BufReadPre,BufFilePre *.ntxt nmap gx }k"*yiW<c-o>$<Plug>NetrwBrowseX
  autocmd BufNewFile,BufReadPre,BufFilePre *.ntxt nnoremap Y "*yiW
  autocmd BufUnload *.ntxt if @* is# @" | let @* = '' | endif
augroup END

augroup extension_mkd
  autocmd!
  autocmd BufNewFile,BufReadPost,BufFilePost *.mkd setlocal filetype=pandoc
augroup END

augroup filetype_lilypond
  autocmd!
  autocmd FileType lilypond setlocal noshowmatch expandtab
augroup END

augroup filetype_python
  autocmd!
  autocmd FileType python setlocal number colorcolumn=80
  autocmd FileType python nnoremap <buffer> <silent> <LocalLeader>r
        \ :below terminal python3 %<cr>
  autocmd FileType python nnoremap <buffer> <LocalLeader>c I# <esc>
  autocmd FileType python nnoremap <buffer> <LocalLeader>C :s/# // \| noh<cr>
  autocmd FileType python vnoremap <buffer> <LocalLeader>c :s/\s*\zs\ze/# / \| noh<cr>
  autocmd FileType python vnoremap <buffer> <LocalLeader>C :s/\s*\zs# // \| noh<cr>
augroup END

augroup filetype_tex
  autocmd!

  function! ToggleLacheck()
    let b:ale_linters_ignore = b:ale_linters_ignore ==# [] ? ['lacheck'] : []
    ALELint " Run linters again
  endfunction

  autocmd FileType tex let b:ale_linters_ignore = [] " Leave all enabled initially
  autocmd FileType tex nnoremap <buffer> <LocalLeader>` :call ToggleLacheck()<cr>
augroup END

augroup filetype_txt
  autocmd!
  autocmd FileType text setlocal spell
  autocmd FileType help setlocal nospell " Fix edge case, since help files are .txt
augroup END

let g:vimsyn_folding='af'
augroup filetype_vim
  autocmd!
  autocmd FileType vim setlocal foldmethod=syntax
augroup END

" Word To Upper Case:
inoremap <Leader>u <esc>gUiwea
nnoremap <Leader>u gUiwe

" Typographer Quotes:
" TODO Eat the added space for abbrevs when I understand how
inoremap <Leader>`` “
inoremap <Leader>'' ”
inoremap <Leader>` ‘
inoremap <Leader>' ’

" Yank All Into Clipboard: and remove final newline from yanked text
nnoremap <Leader>ya :%yank+ \| let @+ = strpart(@+, 0, strlen(@+) - 1)<cr>
nnoremap <Leader>ye :.,$yank+ \| let @+ = strpart(@+, 0, strlen(@+) - 1)<cr>

" vim: textwidth=0
