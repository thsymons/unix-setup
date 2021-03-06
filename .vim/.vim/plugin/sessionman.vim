"============================================================================"
"
"  Vim session manager
"
"  Copyright (c) Yuri Klubakov
"
"  Author:      Yuri Klubakov <yuri.mlists at gmail dot com>
"  Version:     1.04 (2008-06-21)
"  Requires:    Vim 6
"  License:     GPL
"
"  Description:
"
"  Vim provides a ':mksession' command to save the current editing session.
"  This plug-in helps to work with Vim sessions by keeping them in the
"  dedicated location and by providing commands to list all sessions, open
"  session, open last session, close session, save session and show last
"  session.  From a list of sessions you can open session, delete session,
"  edit session and edit extra session script.  Please note that session
"  name can contain spaces and does not have to have a .vim extension.
"
"  On Windows, DOS and OS2 sessions are saved in:
"    "$HOME/vimfiles/sessions"   if $HOME is defined
"    "$APPDATA/Vim/sessions"     if $APPDATA is defined
"    "$VIM/sessions"             otherwise
"  On Unix sessions are saved in:
"    "$HOME/.vim/sessions"
"  If this directory does not exist, it will be created by the :SessionSave
"  command (requires Vim 7).
"
"  :SessionList command creates a new window with session names.
"  At the top of the window there is a help that shows normal mode mappings:
"    q, <ESC>                 - close session list
"    o, <CR>, <2-LeftMouse>   - open session
"    d                        - delete session
"    e                        - edit session
"    x                        - edit extra session script
"  The name of an opened session is saved in g:LAST_SESSION variable which is
"  saved in the viminfo file if 'viminfo' option contains '!'.  It is used to
"  open last session by :SessionOpenLast command.  It can be done when Vim
"  starts (gvim +bd -c OpenLastSession) or any time during a Vim session.
"  You can edit an extra session script to specify additional settings and
"  actions associated with a given session.  If you change values of
"  'expandtab', 'tabstop' or 'shiftwidth', they will be restored to their
"  original values when session is closed or before a new session is opened.
"  When session is opened and 'cscope' is enabled, script calls 'cscope add'
"  for the current directory so make sure it is set correctly for the session.
"
"  :SessionOpen command takes a session name as an argument.  It supports
"  argument completion.
"
"  :SessionOpenLast command opens the g:LAST_SESSION session (see above).
"
"  :SessionClose command wipes out all buffers, kills cscope and clears
"  variables with session name.
"
"  :SessionSave command saves the current editing session.  If s:this_session
"  is empty it asks for a session name.
"
"  :SessionSaveAs command takes a session name as an optional argument.  If
"  there is no argument or it is empty, it asks for a session name (default
"  is the last part of s:this_session).
"
"  :SessionShowLast command shows the content of the g:LAST_SESSION and
"  s:this_session variables.
"
"  If 'sessionman_save_on_exit != 0' (default) then the current editing
"  session will be automatically saved when you exit Vim.
"
"  Plug-in creates a "Sessions" sub-menu under the "File" menu.
"
"============================================================================"

if !has('mksession') || exists('loaded_sessionman')
	finish
endif
let loaded_sessionman = 1

if !exists('sessionman_save_on_exit')
	let sessionman_save_on_exit = 1
endif

let s:cpo_save = &cpo
set cpo&vim

if has("win32") || has("dos32") || has("dos16") || has("os2")
	let s:sessions_path = ($HOME != '') ? $HOME . '/vimfiles' : ($APPDATA != '') ? $APPDATA . '/Vim' : $VIM
	let s:sessions_path = substitute(s:sessions_path, '\\', '/', 'g') . '/sessions'
else
	let s:sessions_path = $HOME . '/.vim/sessions'
endif

let s:et_save = &et
let s:sw_save = &sw
let s:ts_save = &ts
let s:this_session = ''
let s:rel_area = $REL . '/'

"============================================================================"

function! s:RestoreDefaults()
	let &et = s:et_save
	let &sw = s:sw_save
	let &ts = s:ts_save
endfunction

"============================================================================"

function! s:OpenSession(name)
	if a:name != '' && a:name[0] != '"'
		call s:RestoreDefaults()
		execute 'silent! 1,' . bufnr('$') . 'bwipeout!'
		let n = bufnr('%')
		execute 'silent! so ' . s:sessions_path . '/' . a:name
		execute 'silent! bwipeout! ' . n
		if has('cscope')
			silent! cscope kill -1
			silent! cscope add .
		endif
		let g:LAST_SESSION = a:name
		let s:this_session = a:name
	endif
endfunction

"============================================================================"

function! s:CloseSession()
	call s:RestoreDefaults()
	execute 'silent! 1,' . bufnr('$') . 'bwipeout!'
	if has('cscope')
		silent! cscope kill -1
	endif
	unlet! g:LAST_SESSION
	let s:this_session = ''
endfunction

"============================================================================"

function! s:DeleteSession(name)
	if a:name != '' && a:name[0] != '"'
		let save_go = &guioptions
		set guioptions+=c
		if confirm('Are you sure you want to delete "' . a:name . '" session?', "&Yes\n&No", 2) == 1
			setlocal modifiable
			d
			setlocal nomodifiable
			if delete(s:sessions_path . '/' . a:name) != 0
				redraw | echohl ErrorMsg | echo 'Error deleting "' . a:name . '" session file' | echohl None
			endif
		endif
		let &guioptions = save_go
	endif
endfunction

"============================================================================"

function! s:EditSession(name)
	if a:name != '' && a:name[0] != '"'
		bwipeout!
		execute 'silent! edit ' . s:sessions_path . '/' . a:name
		set ft=vim
	endif
endfunction

"============================================================================"

function! s:EditSessionExtra(name)
	if a:name != '' && a:name[0] != '"'
		bwipeout!
		execute 'silent! edit ' . s:sessions_path . '/' . a:name . 'x.vim'
	endif
endfunction

"============================================================================"

function! s:ListSessions()
	let w_sl = bufwinnr("__SessionList__")
	if w_sl != -1
		execute w_sl . 'wincmd w'
		return
	endif
	silent! split __SessionList__

	" Mark the buffer as scratch
	setlocal buftype=nofile
	setlocal bufhidden=wipe
	setlocal noswapfile
	setlocal nowrap
	setlocal nobuflisted

	nnoremap <buffer> <silent> <ESC> :bwipeout!<CR>
	nnoremap <buffer> <silent> q :bwipeout!<CR>
	nnoremap <buffer> <silent> o :call <SID>OpenSession(getline('.'))<CR>
	nnoremap <buffer> <silent> <CR> :call <SID>OpenSession(getline('.'))<CR>
	nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>OpenSession(getline('.'))<CR>
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

	let sessions = substitute(glob(s:sessions_path . '/*'), '\\', '/', 'g')
	let sessions = substitute(sessions, "\\(^\\|\n\\)" . s:sessions_path . '/', '\1', 'g')
	let sessions = substitute(sessions, "\n[^\n]\\+x\\.vim\n", '\n', 'g')
	if sessions == ''
		syn match Error "^\" There.*"
		let sessions = '" There are no saved sessions'
	endif
	silent put =sessions

	0,1d
	execute l
	setlocal nomodifiable
endfunction

"============================================================================"

function! s:SaveSessionAs(...)
	if a:0 == 0 || a:1 == ''
		let name = input('Save session as: ', s:this_session)
	else
		let name = a:1
	endif
	if name != ''
		if v:version >= 700 && finddir(s:sessions_path, '/') == ''
			call mkdir(s:sessions_path, 'p')
		endif
		silent! argdel *
		let g:LAST_SESSION = name
		let s:this_session = name
"		execute 'silent mksession! ' . s:sessions_path . '/' . name
		call s:SaveBuffers(s:sessions_path . '/' . name)
		redraw | echo 'Saved session "' . name . '"'
	endif
endfunction

"============================================================================"

" Save just list of buffers to session file
" Does not save any other state like mksession does
" Supports ADaM style archive defined with $REL environment variable
" Looks for file in local directory, else looks for it in $REL
function s:SaveBuffers(filename)
   let l:session = []
   for l:i in range(1, bufnr('$'))
      if bufexists(l:i) && buflisted(l:i)
	      let l:name = substitute(bufname(l:i),s:rel_area,'','')
		  call add(l:session, "if filereadable(\'" . l:name . "\')")
		  call add(l:session, "   badd " . l:name)
		  call add(l:session, "else")
		  call add(l:session, "   badd \$REL/" . l:name)
		  call add(l:session, "endif")
	   endif
   endfor
   call writefile(l:session,a:filename)
endfunction

"============================================================================"

function! s:SaveSession()
	call s:SaveSessionAs(s:this_session)
endfunction

"============================================================================"

function! s:ReloadSession()
	let l:session = s:this_session
	call s:SaveSession()
	call s:CloseSession()
	call s:OpenSession(l:session)
endfunction

"============================================================================"

function! s:ShowLastSession()
	if exists('g:LAST_SESSION')
		redraw | echo 'Last session is "' . g:LAST_SESSION . '"'
	else
		redraw | echo 'Last session is undefined'
	endif
	echon ', current session is "' . s:this_session . '"'
endfunction

"============================================================================"

function! s:SessionOpenComplete(A, L, P)
	let sessions = substitute(glob(s:sessions_path . '/*'), '\\', '/', 'g')
	return substitute(sessions, '\(^\|\n\)' . s:sessions_path . '/', '\1', 'g')
endfunction

"============================================================================"

command! -nargs=1 -complete=custom,s:SessionOpenComplete SessionOpen call s:OpenSession(<f-args>)
command! -nargs=0 SessionOpenLast if exists('g:LAST_SESSION') | call s:OpenSession(g:LAST_SESSION) | endif
command! -nargs=0 SessionClose call s:CloseSession()
command! -nargs=0 SessionList call s:ListSessions()
command! -nargs=0 SessionSave call s:SaveSession()
command! -nargs=? SessionSaveAs call s:SaveSessionAs(<f-args>)
command! -nargs=0 SessionShowLast call s:ShowLastSession()
command! -nargs=0 SessionReload call s:ReloadSession()

"============================================================================"

"an 10.370 &File.-SessionsSep-				<Nop>
"an 10.371 &File.S&essions.&Open\.\.\.		:SessionList<CR>
"an 10.372 &File.S&essions.Open\ &Last		:SessionOpenLast<CR>
"an 10.373 &File.S&essions.&Close			:SessionClose<CR>
"an 10.374 &File.S&essions.&Save			:SessionSave<CR>
"an 10.374 &File.S&essions.Save\ &As\.\.\.	:SessionSaveAs<CR>
"an 10.374 &File.S&essions.&Reload			:SessionReload<CR>

an &Sessions.Open\.\.\.                     :SessionList<CR>
an Sessions.Open\ Last              		:SessionOpenLast<CR>
an Sessions.Close							:SessionClose<CR>
an Sessions.Save							:SessionSave<CR>
an &Sessions.Save\ &As\.\.\.            	:SessionSaveAs<CR>
an Sessions.Reload							:SessionReload<CR>

aug sessionman
	au VimLeavePre * if sessionman_save_on_exit && s:this_session != '' | call s:SaveSession() | endif
aug END

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: set ts=4 sw=4 noet :
