" Definitions:
" primary hiliting: HiliteGroup0 is always used for new hilite.  This is the hilite that
" will be searched with 'n' or 'b' commands.  When you advance to next match group (or go back
" to prior match group), the new group will be hilited with HiliteGroup0 and will become
" the primary match group.  The old match group will then be re-hilited with its secondary
" hilite color

" Notes:
" let a = bufnr(filename) - returns buffer # for file (or named buffer)
" call badd filename - create new buffer with given name
" getbufline(filename, lnum [, end])
" setline
" append

" Prompt for regular expression, then hilight all occurrences and jump to next occurrence
function! LogMatch#GetSearchRegex()
  if ! empty(s:availHiliteGroups)
    call inputsave()
    echohl Question
    let l:regexp = input('/')
    echohl None
    call inputrestore()
    call s:SetMatch(l:regexp)
  else
    echo "No more highlight groups available - delete unneeded group then retry search"
  endif
endfunction

" Highlight given regex with next available hilite group
function! s:SetMatch(regexp)
  if ! empty(a:regexp)
    if search(a:regexp) != 0
      if s:currentMatchIndex >= 0
        call matchdelete(s:primaryMatchID)
      endif
      let l:hiliteGroup = s:GetNextHiliteGroup()
      call LogMatch#MatchRegex(l:hiliteGroup, a:regexp)
      call LogMatch#SetPrimaryMatch()
    else
      echo "Pattern not found: " . a:regexp
    endif
  endif
endfunction
 
" hilite string currently highlighted
function! LogMatch#MatchSelection()
  let l:regexp = s:GetVisualSelectionAsRegexp()
  call s:SetMatch(l:regexp)
endfunction

" hilite string currently highlighted
function! LogMatch#MatchWordUnderCursor()
  let l:regexp = s:GetWordUnderCursor()
  call s:SetMatch(l:regexp)
endfunction

" Hilite primary match, using currentMatchIndex to find primary regex
function! LogMatch#SetPrimaryMatch()
  let l:regexp = s:activeRegexps[s:currentMatchIndex]
  " Make the match according to the 'ignorecase' setting, like the star command. 
  " (But honor an explicit case-sensitive regexp via the /\C/ atom.) 
  let l:expr = ((&ignorecase && l:regexp !~# '\\\@<!\\C') ? '\c' . l:regexp : l:regexp)

  " Info: matchadd() does not consider the 'magic' (it's always on),
  " 'ignorecase' and 'smartcase' settings. 
  let s:primaryMatchID = matchadd(s:primaryHiliteGroup,l:expr,100)
endfunction

" Hilite given regex, using given hilite group
function! LogMatch#MatchRegex(hiliteGroup, regexp)
  " Make the match according to the 'ignorecase' setting, like the star command. 
  " (But honor an explicit case-sensitive regexp via the /\C/ atom.) 
  let l:expr = ((&ignorecase && a:regexp !~# '\\\@<!\\C') ? '\c' . a:regexp : a:regexp)

  " Info: matchadd() does not consider the 'magic' (it's always on),
  " 'ignorecase' and 'smartcase' settings. 
  let l:m = matchadd(a:hiliteGroup,l:expr)
  call s:SaveMatchRecord(l:m, a:hiliteGroup, l:expr)
endfunction

" highlight next match in current match group
function! LogMatch#HiliteNext(flags)
  if ! empty(s:activeMatchIDs)
    let l:regexp = s:activeRegexps[s:currentMatchIndex]
    if search(l:regexp,a:flags) == 0
      echo "Pattern not found: " . a:regexp
    endif
  else
    echo "No active match"
  endif
endfunction

" Advance to next match group to become current match group
" Remove default hilite from current match group
" Add default hilite to next match group
function! LogMatch#SelectNextMatchGroup()
  if ! empty(s:activeMatchIDs)
    let s:currentMatchIndex += 1
    if s:currentMatchIndex >= len(s:activeMatchIDs)
      let s:currentMatchIndex = 0
    endif
    call matchdelete(s:primaryMatchID)
    let l:regexp = s:activeRegexps[s:currentMatchIndex]
    let s:primaryMatchID = matchadd(s:primaryHiliteGroup,l:regexp,100)
  endif
endfunction

" Go back to prior match group to become current match group
" Remove default hilite from current match group
" Add default hilite to prior match group
function! LogMatch#SelectPriorMatchGroup()
  if ! empty(s:activeMatchIDs)
    let s:currentMatchIndex -= 1
    if s:currentMatchIndex < 0
      let s:currentMatchIndex = len(s:activeMatchIDs) - 1
    endif
    call matchdelete(s:primaryMatchID)
    let l:regexp = s:activeRegexps[s:currentMatchIndex]
    let s:primaryMatchID = matchadd(s:primaryHiliteGroup,l:regexp,100)
  endif
endfunction

" Remove hilite from current match group
" Advance default hilite to next match group
function! LogMatch#DeleteCurrentMatchGroup()
  if ! empty(s:activeMatchIDs)
    let l:saveCMI = s:currentMatchIndex
    " remove primary hiliting for current match group, advance to next (if any)
    if len(s:activeMatchIDs) > 1
      call LogMatch#SelectNextMatchGroup()
    else
      call matchdelete(s:primaryMatchID)
    endif
    " remove secondary hiliting for current match group
    let l:m = s:activeMatchIDs[l:saveCMI]
    let l:hg = s:activeHiliteGroups[l:saveCMI]
    call matchdelete(l:m)
    " release hilite group, update active lists
    call add(s:availHiliteGroups,l:hg)
    unlet s:activeMatchIDs[l:saveCMI]
    unlet s:activeHiliteGroups[l:saveCMI]
    unlet s:activeRegexps[l:saveCMI]
    " update currentMatchIndex
    if ! empty(s:activeMatchIDs)
      if s:currentMatchIndex > l:saveCMI
        let s:currentMatchIndex -= 1
      endif
    else
      let s:currentMatchIndex = -1
    endif
    echo
  endif
endfunction

" Removes hilite from all match groups
function! LogMatch#DeleteAllMatchGroups()
  while ! empty(s:activeMatchIDs)
    call LogMatch#DeleteCurrentMatchGroup()
  endwhile
endfunction

" Save given match ID and HiliteGroup as current match record
function! s:SaveMatchRecord(matchID, HiliteGroup, regexp)
  call add(s:activeMatchIDs,a:matchID)
  call add(s:activeHiliteGroups,a:HiliteGroup)
  call add(s:activeRegexps,a:regexp)
  let s:currentMatchIndex = len(s:activeMatchIDs) - 1
endfunction

" Returns next available log group
function! s:GetNextHiliteGroup()
  if ! empty(s:availHiliteGroups)
    let l:HiliteGroup = s:availHiliteGroups[0]
    unlet s:availHiliteGroups[0]
    return l:HiliteGroup
  else
    " no more hilite groups left - reuse oldest one
  endif
endfunction

" List active hilite groups
function! LogMatch#ListHiliteGroups()
  let l:i = 0
  while l:i < len(s:activeMatchIDs)
    echo l:i . ": " . s:activeHiliteGroups[l:i] . " " . s:activeRegexps[l:i]
    let l:i += 1
  endwhile
  execute 'so ' . s:saveLogMatchDir . '/' . s:thisLogMatchFile
  echo "Current match file: " . s:saveLogMatchDir . '/' .s:thisLogMatchFile
endfunction

"===================================================================
" File I/O Functions

" Displays save matches files, lets user select one which is then sourced
" Sourced file with update hiliting to match groups defined in file
function! LogMatch#OpenMatchesFile(name)
  if a:name != '' && a:name[0] != '"'
"    execute 'silent! 1,' . bufnr('$') . 'bwipeout!'
    let n = bufnr('%')
    execute 'silent! bwipeout! ' . n
    let s:thisLogMatchFile = a:name
    call LogMatch#DeleteAllMatchGroups()
    execute 'so ' . s:saveLogMatchDir . '/' . s:thisLogMatchFile
  endif
endfunction


" Save currently define match groups to given filename
" Always stored in s:saveLogMatchDir
function! LogMatch#SaveMatchesFile(filename)
  let l:lines = []
  let l:i = 0
  while l:i < len(s:activeMatchIDs)
    call add(l:lines, "call LogMatch#MatchRegex(\'" . s:activeHiliteGroups[l:i] . "\', \'" . s:activeRegexps[l:i] . "\')")
    let l:i += 1
  endwhile
  if ! empty(s:activeMatchIDs)
    call add(l:lines, "let s:currentMatchIndex = " . s:currentMatchIndex)
    call add(l:lines, "call LogMatch#SetPrimaryMatch()")
  endif
  call writefile(l:lines,a:filename)
endfunction

" Prompts for new filename to save match groups
" Calls SaveMatchesFile to save match groups
function! LogMatch#SaveMatchesAs(...)
  if a:0 == 0 || a:1 == ''
    let name = input('Save session as: ', s:thisLogMatchFile)
  else
    let name = a:1
  endif
  if name != ''
    silent! argdel *
    let s:thisLogMatchFile = name
    call LogMatch#SaveMatchesFile(s:saveLogMatchDir . '/' . name)
    redraw | echo 'Saved match group "' . name . '"'
  endif
endfunction

" Called from menu to save current match groups
function! LogMatch#SaveMatches()
  call LogMatch#SaveMatchesAs(s:thisLogMatchFile)
endfunction

function! LogMatch#ListMatches()
  let w_sl = bufwinnr("__MatchesList__")
  if w_sl != -1
    execute w_sl . 'wincmd w'
    return
  endif
  silent! split __MatchesList__

  " Mark the buffer as scratch
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nowrap
  setlocal nobuflisted

  nnoremap <buffer> <silent> <ESC> :bwipeout!<CR>
  nnoremap <buffer> <silent> q :bwipeout!<CR>
  nnoremap <buffer> <silent> o :call LogMatch#OpenMatchesFile(getline('.'))<CR>
  nnoremap <buffer> <silent> <CR> :call LogMatch#OpenMatchesFile(getline('.'))<CR>
  nnoremap <buffer> <silent> <2-LeftMouse> :call LogMatch#OpenMatchesFile(getline('.'))<CR>
  nnoremap <buffer> <silent> d :call <SID>DeleteSession(getline('.'))<CR>
  nnoremap <buffer> <silent> e :call <SID>EditSession(getline('.'))<CR>
  nnoremap <buffer> <silent> x :call <SID>EditSessionExtra(getline('.'))<CR>

  syn match Comment "^\".*"
  put ='\"-----------------------------------------------------'
  put ='\" q, <ESC>                 - close session list'
  put ='\" o, <CR>, <2-LeftMouse>   - open session'
  put ='\" d                        - delete session'
  put ='\" e                        - edit session'
  put ='\" x                        - edit extra session script'
  put ='\"-----------------------------------------------------'
  put =''
  let l = line(".")

  let matchfiles = substitute(glob(s:saveLogMatchDir . '/*'), '\\', '/', 'g')
  let matchfiles = substitute(matchfiles, "\\(^\\|\n\\)" . s:saveLogMatchDir . '/', '\1', 'g')
  let matchfiles = substitute(matchfiles, "\n[^\n]\\+x\\.vim\n", '\n', 'g')
  if matchfiles == ''
    syn match Error "^\" There.*"
    let matchfiles = '" There are no saved match files'
  endif
  silent put =matchfiles

  0,1d
  execute l
  setlocal nomodifiable
endfunction

"===================================================================
" Misc functions

" Return string currently selected in visual mode
function! s:GetVisualSelection()
	let save_a = @a
	silent normal! gv"ay
	let res = @a
	let @a = save_a
	return res
endfunction

" Return string currently selected in visual mode as regex
function! s:GetVisualSelectionAsRegexp()
	return substitute(s:GetVisualSelection(), '\n', '', 'g')
endfunction

" Returns word currently under cursor
function! s:GetWordUnderCursor()
  return expand("<cword>")
endfunction

" Initialize this script
function! s:InitLogMatch()
  let s:activeMatchIDs = []
  let s:availHiliteGroups = []
  let s:activeHiliteGroups = []
  let s:activeRegexps = []
  let s:primaryHiliteGroup = "PrimaryHiliteGroup"
  let s:saveLogMatchDir = $HOME . '/.vim/LogMatches'
  let s:thisLogMatchFile = 'default'
  let l:m = 0
  while hlexists("HiliteGroup" . l:m)
    call add(s:availHiliteGroups, "HiliteGroup" . l:m)
    let l:m += 1
  endwhile
  let s:currentMatchIndex = -1
endfunction

call s:InitLogMatch()
