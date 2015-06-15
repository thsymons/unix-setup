

"set shell=/bin/csh\ -f

set shiftwidth=2
set tabstop=2
set autoindent
set expandtab
set cindent
set nobackup
set noswapfile
set ignorecase
set incsearch
set hlsearch
set cpoptions=aAceFs

let mapleader=","

" Set highlighting search options - use ':hi Search' to display current settings
"highlight Search guibg=LightRed

"set background=dark
"colorscheme mine
syntax enable
source $VIMRUNTIME/macros/matchit.vim
"Auto load SystemVerilog syntax file
"au BufNewFile,BufRead *.v,*.sv,*.svh,*.vic setf system_verilog

" Python indenting
"au BufRead,BufNewFile *.py set tabstop=2|set shiftwidth=2|set expandtab|set autoindent
"autocmd FileType *.py set tabstop=2|set shiftwidth=2|set expandtab|set autoindent
" See .vim/ftplugin/python.vim instead
filetype plugin indent on

" File suffix swap commands
cmap HH e %:r.h
cmap CC e %:r.c
"cmap SS e %:r.sv
"cmap IF e %:r.if
"cmap VV e %:r.v
cmap TT s/^\s\*/\\t/
cmap HPP e %:r.hpp
cmap CPP e %:r.cpp

"convert2unix
cmap D2U %s///g

" Close current file
cmap Close bdelete %

" Insert standard coder header/footer
cmap Hdr r /import/rapid/copyright.txt
cmap Ftr r ~/bin/code_footer.txt

cmap reload so ~/.vimrc

" Create a macro 'a': qa commands q
" Execute macro 'a': @a

"set path=**
"set path=.,./*,models/*,units/*
"set suffixesadd=.svh,.sv,.v,.cpp

function! SuperRetab() range
     let x = 0
     while x < 10
             exe a:firstline . ',' . a:lastline . 's/^\([ ]*\)[ ]\{' . &sw . '}/\1\t\2/e'
             let x = x + 1
     endwhile
endfunction

"NeoBundle Scripts-----------------------------
if has('vim_starting')
  set nocompatible               " Be iMproved

  " Required:
  set runtimepath+=/home/tsymons/.vim/bundle/neobundle.vim/
endif

" Required:
"call neobundle#begin(expand('/home/tsymons/.vim/bundle'))

" Let NeoBundle manage NeoBundle
" Required:
"NeoBundleFetch 'Shougo/neobundle.vim'

" My Bundles here:
"NeoBundle 'Shougo/neosnippet.vim'
"NeoBundle 'Shougo/neosnippet-snippets'
"NeoBundle 'tpope/vim-fugitive'
"NeoBundle 'kien/ctrlp.vim'
"NeoBundle 'flazz/vim-colorschemes'
"NeoBundle 'Mark--Karkat'            " Create mark  ;m        Goto next mark     ;/


" You can specify revision/branch/tag.
"NeoBundle 'Shougo/vimshell', { 'rev' : '3787e5' }

" Required:
"call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
"NeoBundleCheck
"End NeoBundle Scripts-------------------------

" search next of any mark
nnoremap `n :call mark#SearchAnyMark(0)<CR>
" search previous of any mark
nnoremap `p :call mark#SearchAnyMark(1)<CR>
" search next of current mark
nnoremap `j :call mark#SearchCurrentMark(0)<CR>
" search previous of current mark
nnoremap `k :call mark#SearchCurrentMark(1)<CR>

" *** Notes ***
" change all tabs to spaces: %retab!
" reset indentation: ==
" open file under cursor: gf
"
" * For regular expressions:
" Can use perl RE pattern matching, but must preceed all control characters
" with a '\'.
" For example: 
" perl syntax: s/\s+([^:]+)/xxx/
" vim syntax: s/\s\+\([^:]\+\)/xxx/
" Note how + operator and ( and ) operators are preceeded by '\'
" Also note that [ and ] and ^ are NOT preceeded by '\' - go figure.

" Vim configuration, etc. can be found in $VIMRUNTIME (cd there from inside vim)

" Reverse a group of lines:
" Go to first line: mark it with 'mt' (just type mt in command mode)
" Go to last line: :'t+1,.g^/m 't

