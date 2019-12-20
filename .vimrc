setglobal nocompatible
"source $VIMRUNTIME/mswin.vim

" TODO Check whether bufname(1) ends with .git/COMMIT_EDITMSG and exit early if so
" echom "Filetype at startup:" bufname(1)
" finish
" Also take a look at: https://til.hashrocket.com/posts/c265634512-vim-startup-time-profiling

" Temporary function to fix a bunch of Python files that have awful formatting
function! FixPython()
  set tabstop=4
  retab
  %s/\v[ ]+$//e  " Remove trailing spaces
  %s/[:,]\zs\ze[^ ]/ /ge " Commas and colons are followed by spaces (or newlines)
  %s/#\zs\ze[^ ]/ /e  " Comments start with a space
  %s/\vprint\zs (.*)/(\1)/e  " Use print as a function
  %s/[ ]\ze[:,]//ge  " Remove spaces before colons and commas
  %s/"/'/ge  " Use single quotes
  %s/\v%(\(.{-})@<=[ ]?\=[ ]?/=/ge  " Remove spaces around `=` in function parameters
endfunction

let $MYVIMHOME=fnameescape(expand('<sfile>:p:h'))

"alternates from: https://github.com/justinmk/config/blob/master/.vimrc
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

" set window size when starting GUI
if s:is_gui && has('vim_starting')
  " define the function that does the work
  function! s:setwinsize()
    let l:posx = getwinposx() " get x position before resizing

    setglobal lines=999 " use full screen height
    setglobal columns=999 " start with full screen width

    let l:posy = getwinposy() " get y position potentially adjusted by resizing

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

    " put the window back where the windowing system first put it (horizontally)
    execute "winpos" l:posx l:posy
  endfunction

  " TODO Always call the function immediately; On Linux, set lines=99 in autocmd
  " call the function
  if s:is_windows
    " Windows can run this right away and avoid a flash of the large window size
    call s:setwinsize()
  else
    " run at GUIEnter so that &columns will be limited by screen size
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
" TODO https://github.com/tpope/vim-eunuch " Convenient shell wrappers like :Rename
Plug 'tpope/vim-dispatch'

Plug 'nathanaelkane/vim-indent-guides'
  let g:indent_guides_color_change_percent = 25
  let g:indent_guides_guide_size = 1

" SYNTAX HIGHLIGHTING AND BEHAVIOR:
Plug 'kchmck/vim-coffee-script', {'for': 'coffee'}
Plug 'pangloss/vim-javascript', {'for': 'javascript'}
Plug 'glench/vim-jinja2-syntax', {'for': ['jinja.html', 'jinja']} " Also for Nunjucks
Plug 'gisraptor/vim-lilypond-integrator', {'for': 'lilypond'}
Plug 'mustache/vim-mustache-handlebars'
Plug 'vim-pandoc/vim-pandoc', {'for': 'pandoc'}
Plug 'vim-pandoc/vim-pandoc-syntax', {'for': 'pandoc'}
Plug 'digitaltoad/vim-pug', {'for': 'pug'}

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

Plug 'mxw/vim-jsx', {'for': 'javascript.jsx'}
  let g:jsx_ext_required = 1 " Don't treat .js files as JSX

Plug 'plasticboy/vim-markdown', {'for': 'markdown'}
  let g:vim_markdown_conceal = 0
  let g:vim_markdown_folding_style_pythonic = 1
  let g:vim_markdown_frontmatter = 1
  let g:vim_markdown_toc_autofit = 1

" TODO Plug 'https://github.com/quramy/tsuquyomi' " TypeScript IDE behavior for Vim
Plug 'HerringtonDarkholme/yats.vim', {'for': ['typescript', 'typescript.tsx']}

" SYNTAX CHECKERS:
" TODO: Decide if I want to load syntastic (or ale) only for gvim
let g:ale_completion_enabled = 1
Plug 'w0rp/ale'
  let g:ale_linters = {
        \ 'javascript': [],
        \ 'markdown': [],
        \ 'python': ['pycodestyle']
        \ }

  " Define key mappings
  nmap <silent> <c-k> <plug>(ale_previous_wrap)
  nmap <silent> <c-j> <plug>(ale_next_wrap)

  " Disable ale in diff mode
  augroup NoAle
    autocmd!
    autocmd VimEnter * if &diff | ALEDisable | endif
    autocmd OptionSet diff ALEDisableBuffer
  augroup END

  " Configure status line format
  let &g:statusline = "%q" " [Quickfix List], [Location List] or empty
  let &g:statusline .= "%w" " Preview window flag [Preview]
  let &g:statusline .= "%<%f\ " " Path to file, truncated on the left if needed
  let &g:statusline .= "%h%m%r" " Help, modified, and readonly flags
  " let &g:statusline .= "\ %#warningmsg#" " Switch highlighting
  " let &g:statusline .= "%{SyntasticStatuslineFlag()}" " Show Syntastic info
  " let &g:statusline .= "%*" " Reset highlighting to default
  let &g:statusline .= "%=" " Separation between left- and right-aligned items
  " Note: %c = column number in bytes; %v = virtual column number
  let &g:statusline .= "%-8.(%l,%c%)" " Left-justify line & col number w/ minwidth of 8
  let &g:statusline .= "\ %P" " Percentage through file (or Top/Bot/All)

" Plug 'vim-syntastic/syntastic'
"   " Default checking options
"   let g:syntastic_mode_map = {
"         \ "mode": "passive",
"         \ "active_filetypes": ['html', 'python'],
"         \ "passive_filetypes": []}
"   " Define key mappings
"   function! ToggleSyntasticSkipChecks()
"     let b:syntastic_skip_checks = !get(b:, 'syntastic_skip_checks', 0)
"     SyntasticReset
"     echo "Syntax checking for this buffer is:" (b:syntastic_skip_checks ? "off" : "on")
"   endfunction
"   nnoremap <Leader><Leader>`l :call ToggleSyntasticSkipChecks()<cr>
"   nnoremap <Leader>`l :SyntasticCheck<cr>
"   " let g:syntastic_always_populate_loc_list = 1
"   let g:syntastic_auto_loc_list = 1
"   let g:syntastic_check_on_open = 0
"   let g:syntastic_check_on_wq = 0
" 
" " JavaScript
" Plug 'sindresorhus/vim-xo', {'for': 'javascript'}
"   let g:syntastic_javascript_checkers = ['xo']
"   let g:syntastic_javascript_xo_lint_args = '--space=4'
"   let g:syntastic_javascript_xo_args = '--space=4'
"   " let g:syntastic_javascript_eslint_generic = 1
"   " let g:syntastic_javascript_checkers = ['eslint']
" 
" " Python
"   let g:syntastic_python_checkers = ['pycodestyle']
" 
" " HTML
"   let g:syntastic_html_checkers = ['htmlhint']
" 
"   " let g:syntastic_html_checkers = ['validator', 'w3']
" 
"   " let g:syntastic_html_checkers = ['validator']
"   " let g:syntastic_html_validator_exec =  "C:\\Program Files\\Git\\mingw32\\bin\\curl.exe"
"   " let g:syntastic_html_validator_parser =  "html5"
" 
"   " let g:syntastic_html_checkers = ['w3']
"   " let g:syntastic_html_w3_exec =  "C:/Program Files/Git/mingw32/bin/curl.exe"

call plug#end()

" Might use one of these for Python at some point (linked from Syntastic README):
" https://github.com/davidhalter/jedi-vim
" https://github.com/python-mode/python-mode

if exists('s:is_fresh_plug_install')
  PlugInstall
  unlet s:is_fresh_plug_install
endif

augroup filetype_vim
  autocmd!
  autocmd FileType vim setlocal shiftwidth=2 expandtab
augroup END

if has('vim_starting')
  " Set this only when starting up so matches aren't shown again when reloading .vimrc
  setglobal hlsearch

  "Jump to last known cursor position when opening a file. - from vimrc_example.vim
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

"Vim_Pandoc Configuration:
let g:pandoc#filetypes#pandoc_markdown = 0 "Don't use pandoc for all markdown extensions
let g:pandoc#formatting#equalprg = "" "Don't change default indenting
let g:pandoc#keyboard#use_default_mappings = 0 "Disable key mappings
let g:pandoc#syntax#conceal#blacklist = [
      \"image",
      \"subscript",
      \"superscript",
      \"codeblock_start",
      \"codeblock_delim",
      \"definition",
      \"list",
      \]
      "\"newline",
let g:pandoc#syntax#conceal#cchar_overrides = {
      \"newline": " ",
      \"image": "i",
      \}
let g:pandoc#syntax#codeblocks#embeds#langs = [
      \"python",
      \"javascript",
      \]

" Pandoc Markdown To HTML:
nnoremap <silent> <Leader>pd :silent Spawn! pandoc % -o %:r".html" --from markdown+link_attributes-auto_identifiers --to html5 --standalone --smart<cr>
nnoremap <silent><Leader>pp :silent py from subprocess import Popen; Popen(["pandoc", "-o", "test.html", "-s", "-f", "markdown-auto_identifiers", "-t", "html5", "test.pdc"])<cr>

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

  setglobal mouse=a "enable the mouse when running via terminal
  setglobal cryptmethod=blowfish2
  setglobal backupcopy=yes " https://github.com/parcel-bundler/parcel/issues/221
  "setglobal selection=old "TODO find out why this was exclusive. Check :behave command.
  colorscheme pablo
  highlight Special guifg=#2222ff
  highlight LineNr guifg=Red guibg=#202020
  setglobal conceallevel=2
  setglobal fileformats=unix,dos,mac
  setglobal softtabstop=-1 " Use the value of shiftwidth
  setglobal ignorecase
  setglobal smartcase
  setglobal showcmd
  " These are local options, but we set global as well to affect windows opened later
  set linebreak
  set breakindent
  let &showbreak = '> '
  set foldmethod=marker

  " TODO Could look into NerdTree or https://github.com/justinmk/vim-dirvish
  let g:netrw_banner = 0 " Hide banner
  let g:netrw_fastbrowse = 0 " https://github.com/tpope/vim-vinegar/issues/13
  let g:netrw_liststyle = 3 " Tree view
  let g:netrw_winsize = 30 " This is a percentage of the available space
endif

if !s:is_gui
  augroup vim_enter
    autocmd!
    " TODO Find a better way to see the statusline that still identifies current window
    autocmd VimEnter * highlight StatusLine cterm=reverse
  augroup END
endif

" TODO make function(s) to change fonts/sizes
"setglobal guifont=Courier_New:h9 "the font used for :hardcopy (but different size)
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

nnoremap <Leader>ev :split $MYVIMRC<cr>
nnoremap <Leader><Leader>ev :tabedit $MYVIMRC<cr>
nnoremap <Leader>sv :source $MYVIMRC \| doautocmd FileType<cr>
" Execute Current Line: "good for ex commands like: !pandoc %:p
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

" Completely clear the content saved in a named register
command! -nargs=1 ClearRegister call setreg('<args>', [])

augroup filetype_autohotkey
  autocmd!
  autocmd FileType autohotkey setlocal expandtab shiftwidth=4
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
  autocmd FileType gitcommit setlocal spell textwidth=72 formatoptions-=l
  " Don't know why I need this, but commits stopped highlighting and this fixes it (2018)
  " TODO figure out why this is needed, hopefully remove it or put it under "if Windows:"
  autocmd FileType gitcommit hi SpellBad cterm=underline
augroup END

augroup filetype_html
  autocmd!
  autocmd FileType html setlocal foldmethod=indent foldlevel=99 shiftwidth=2 expandtab
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
  " I'm not sure cinoptions had any effect
  "autocmd Filetype javascript setlocal cinoptions=+2s "continuation lines
  "autocmd Filetype javascript setlocal cinoptions+=:0 "switch, case
  autocmd FileType javascript,typescript setlocal shiftwidth=4 expandtab number
  autocmd FileType javascript,typescript setlocal indentkeys+=0?,0<:>,0.
  autocmd FileType javascript,typescript setlocal foldmethod=syntax
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
  autocmd FileType json setlocal shiftwidth=4 expandtab number conceallevel=0
  autocmd FileType json setlocal foldmethod=syntax foldlevel=99
  autocmd BufReadPost package.json setlocal shiftwidth=2
augroup END

augroup filetype_css
  autocmd!
  autocmd FileType css,scss setlocal expandtab shiftwidth=2 foldmarker={,}
  autocmd FileType css,scss nnoremap <buffer> <LocalLeader>c I/*<esc>A*/<esc>
  autocmd FileType css,scss nnoremap <buffer> <LocalLeader>C :s,/\*\(.*\)\*/,\1,e \| noh<cr>
  autocmd FileType css,scss inoremap <buffer> { {<cr>}<esc>O
augroup END

augroup filetype_markdown
  autocmd!
  autocmd FileType markdown setlocal shiftwidth=4 expandtab
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

augroup filetype_pandoc
  autocmd!
  autocmd FileType pandoc setlocal shiftwidth=4 expandtab
augroup END

augroup filetype_pug
  autocmd!
  autocmd FileType pug setlocal shiftwidth=2 expandtab
augroup END

augroup extension_mkd
  autocmd!
  autocmd BufNewFile,BufReadPost,BufFilePost *.mkd setlocal filetype=pandoc shiftwidth=2 expandtab
augroup END

augroup filetype_lilypond
  autocmd!
  autocmd FileType lilypond setlocal noshowmatch expandtab
augroup END

augroup filetype_python
  autocmd!
  autocmd FileType python setlocal shiftwidth=4 expandtab number
  if s:is_gui
    autocmd FileType python let &columns = 80 + &numberwidth
  endif
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

  autocmd FileType tex setlocal shiftwidth=2 expandtab
  autocmd FileType tex let b:ale_linters_ignore = [] " Leave all enabled initially
  autocmd FileType tex nnoremap <buffer> <LocalLeader>` :call ToggleLacheck()<cr>
augroup END

augroup filetype_txt
  autocmd!
  autocmd BufNew,BufRead *.txt setlocal spell
  autocmd Syntax help setlocal nospell
augroup END

augroup filetype_yaml
  autocmd!
  autocmd FileType yaml setlocal expandtab shiftwidth=2
augroup END

nnoremap <Leader><Leader>rs
      \ :edit $HOME/Desktop/Txt/RS songs.txt \|
      \ split $HOME/Desktop/Txt/RS abilities.txt \| resize<cr><cr>

" Word To Upper Case:
inoremap <Leader>u <esc>gUiwea
nnoremap <Leader>u gUiwe

" Typographer Quotes:
" TODO Eat the added space for abbrevs when I understand how
inoremap <Leader>`` “
inoremap <Leader>'' ”
inoremap <Leader>` ‘
inoremap <Leader>' ’

"nnoremap \w :%s/^\s*// \| noh \| echo        "Delete indentation"<cr>
nnoremap <silent> <LocalLeader>s :pydo return line.strip()<cr>

" Yank All Into Clipboard: and remove final newline from yanked text
nnoremap <Leader>ya :%yank+ \| let @+ = strpart(@+, 0, strlen(@+) - 1)<cr>
nnoremap <Leader>ye :.,$yank+ \| let @+ = strpart(@+, 0, strlen(@+) - 1)<cr>

" vim: textwidth=0
