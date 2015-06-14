set nocompatible

set guioptions-=T

"set viminfo='20,"50,h,%10
set guifont=monospace\ 8
"set guifont=monospace\ 10

"set guifont=miscFixed\ 7 
"set guifont=Fixed\ 11 
"set guifont=Clean\ 9
"set guifont=--courier-medium-r-normal-*-*-80-*-*-m-*-iso8859-1
"set guifont=-misc-fixed-medium-r-semicondensed-*-*-120-*-*-c-*-koi12-r
"set guifont=-misc-fixed-medium-r-semicondensed-*-*-120-*-*-c-*-koi8-r
"set guifont=-misc-fixed-medium-r-semicondensed-*-*-160-*-*-c-*-koi16-r
"highlight Normal guibg=black guifg=white
"colorscheme mine
colorscheme desert
"colorscheme ir_black

"set path=.,./*,models/*,units/*
set suffixesadd=.svh,.sv,.v,.cpp
set number

syntax enable
source $VIMRUNTIME/macros/matchit.vim
"Auto load SystemVerilog syntax file
au BufNewFile,BufRead *.v,*.sv,*.svh,*.vic setf system_verilog


" Set highlighting search options - use ':hi Search' to display current settings
"highlight Search guibg=LightBlue guifg=black

set sessionoptions=sesdir
"set sessionoptions=curdir

"highlight PrimaryHiliteGroup ctermbg=red       ctermfg=Black guibg=red       guifg=Black
"highlight HiliteGroup0       ctermbg=lightblue ctermfg=Black guibg=lightblue guifg=Black
"highlight HiliteGroup1       ctermbg=yellow    ctermfg=Black guibg=yellow    guifg=Black
"highlight HiliteGroup2       ctermbg=blue      ctermfg=White guibg=blue      guifg=White
"highlight HiliteGroup3       ctermbg=green     ctermfg=Black guibg=green     guifg=Black
"highlight HiliteGroup4       ctermbg=magenta   ctermfg=Black guibg=magenta   guifg=Black
"highlight HiliteGroup5       ctermbg=cyan      ctermfg=Black guibg=cyan      guifg=Black
"highlight HiliteGroup6       ctermbg=gray      ctermfg=Black guibg=gray      guifg=Black
"highlight HiliteGroup7       ctermbg=white     ctermfg=Black guibg=white     guifg=Black
"highlight HiliteGroup8       ctermbg=white     ctermfg=Black guibg=#FF7F00   guifg=white "DarkOrange1
"highlight HiliteGroup9       ctermbg=white     ctermfg=Black guibg=#FF7256   guifg=Black "Coral1
"highlight HiliteGroup10      ctermbg=white     ctermfg=Black guibg=#FF1493   guifg=Black "DeepPink1
"highlight HiliteGroup11      ctermbg=white     ctermfg=Black guibg=#008B8B   guifg=Black "Cyan4
"highlight HiliteGroup12      ctermbg=white     ctermfg=Black guibg=#D2691E   guifg=Black "Chocolate
"highlight HiliteGroup13      ctermbg=white     ctermfg=Black guibg=#FA8072   guifg=Black "Salmon
"highlight HiliteGroup14      ctermbg=white     ctermfg=Black guibg=#698B22   guifg=Black "OliveDrab4
"highlight HiliteGroup15      ctermbg=white     ctermfg=Black guibg=#FFB90F   guifg=Black "DarkGoldenrod1





