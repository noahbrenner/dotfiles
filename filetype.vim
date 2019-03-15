" Noah's fileype file
if exists("did_load_filetypes")
  finish
endif

augroup filetypedetect
  " TODO Currently, this block is duplicated in .vimrc which is bad. Remove it
  " from here as soon as possible, probably when .vimrc is in a default location.
  autocmd! BufRead,BufNewFile *.ejs.* let &filetype = &filetype
	\ ? 'jst.' . &filetype
	\ : 'jst.' . expand('%:e')
  autocmd! BufRead,BufNewFile *.*.ejs let &filetype = 'jst.' . expand('%:r:e')

  autocmd! BufRead,BufNewFile *.json	setfiletype json
  autocmd! BufRead,BufNewFile *.jsonp	setfiletype json
  " TODO Do I need the "!"?
  " I might not, especially since I'm using "setfiletype" instead of "set filetype"
  autocmd! BufRead,BufNewFile *.md	setfiletype markdown
  "autocmd! BufRead,BufNewFile *.md	setfiletype pandoc
augroup END
