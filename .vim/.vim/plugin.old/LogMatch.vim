" Usage
"         / - prompt for search
" <Leader>m - match current selection
" <Leader>w - match word under cursor
"         n - go forward to next match in current match group
"         b - go backward
"         + - advance to next match group
"         - - go back to prior match group
" <Leader>d - delete current match group
" <Leader>c - delete all match groups
"
" Use 'Matches' menu to open or save match groups from/to a file

" Avoid installing twice
finish
if exists('g:loadedLogMatch')
  finish
endif
let g:loadedLogMatch = 1

noremap / :call LogMatch#GetSearchRegex()<CR>
noremap <silent> <Plug>LogMatchMatchSelection :<C-u>call LogMatch#MatchSelection()<CR>
noremap <silent> <Plug>LogMatchHiliteForward :call LogMatch#HiliteNext('')<CR>
noremap <silent> <Plug>LogMatchHiliteBackward :call LogMatch#HiliteNext('b')<CR>
noremap <silent> <Plug>LogMatchNextMatchGroup :call LogMatch#SelectNextMatchGroup()<CR>
noremap <silent> <Plug>LogMatchPriorMatchGroup :call LogMatch#SelectPriorMatchGroup()<CR>
noremap <silent> <Plug>LogMatchDeleteCurrentMatchGroup :call LogMatch#DeleteCurrentMatchGroup()<CR>
noremap <silent> <Plug>LogMatchDeleteAllMatchGroups :call LogMatch#DeleteAllMatchGroups()<CR>
noremap <silent> <Plug>LogMatchList :call LogMatch#ListHiliteGroups()<CR>
nnoremap <silent> <Leader>w :call LogMatch#MatchWordUnderCursor()<CR>

nmap <silent> n <Plug>LogMatchHiliteForward
nmap <silent> b <Plug>LogMatchHiliteBackward
nmap <silent> + <Plug>LogMatchNextMatchGroup
nmap <silent> - <Plug>LogMatchPriorMatchGroup
vmap <Leader>m <Plug>LogMatchMatchSelection
nmap <silent> <Leader>d <Plug>LogMatchDeleteCurrentMatchGroup
nmap <silent> <Leader>c <Plug>LogMatchDeleteAllMatchGroups
nmap <silent> <Leader>l <Plug>LogMatchList

command! -nargs=0 MatchesList call LogMatch#ListMatches()
command! -nargs=0 MatchesSave call LogMatch#SaveMatches()
command! -nargs=? MatchesSaveAs call LogMatch#SaveMatchesAs(<f-args>)

an &Matches.Open\.\.\.             :MatchesList<CR>
an Matches.Save                    :MatchesSave<CR>
an &Matches.Save\ &As\.\.\.        :MatchesSaveAs<CR>

" Define default highlights - can be overridden in user .vimrc file
highlight def PrimaryHiliteGroup ctermbg=red       ctermfg=Black guibg=red       guifg=Black
highlight def HiliteGroup0       ctermbg=lightblue ctermfg=Black guibg=lightblue guifg=Black
highlight def HiliteGroup1       ctermbg=yellow    ctermfg=Black guibg=yellow    guifg=Black
highlight def HiliteGroup2       ctermbg=blue      ctermfg=White guibg=blue      guifg=White
highlight def HiliteGroup3       ctermbg=green     ctermfg=Black guibg=green     guifg=Black
highlight def HiliteGroup4       ctermbg=magenta   ctermfg=Black guibg=magenta   guifg=Black
highlight def HiliteGroup5       ctermbg=cyan      ctermfg=Black guibg=cyan      guifg=Black
highlight def HiliteGroup6       ctermbg=gray      ctermfg=Black guibg=gray      guifg=Black
highlight def HiliteGroup7       ctermbg=white     ctermfg=Black guibg=white     guifg=Black


