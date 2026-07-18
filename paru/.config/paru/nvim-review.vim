" paru PKGBUILD review only — sourced via FileManagerFlags (-S)
" Wider NERDTree, open first *.diff (or PKGBUILD), place tree cursor on diff.
" (Do not set columns/lines — that corrupts the TUI with lightline.)

let g:NERDTreeWinSize = 45

" NERDTree hijacks the directory paru passes in; collapse to one window first
" so we don't end up with tree + file + leftover scratch.
if exists('t:NERDTreeBufName') && bufwinnr(t:NERDTreeBufName) != -1
  NERDTreeClose
endif
silent! only

let s:diffs = glob('*.diff', 0, 1)
if empty(s:diffs)
  let s:diffs = glob('**/*.diff', 0, 1)
endif

if !empty(s:diffs)
  execute 'edit' fnameescape(s:diffs[0])
else
  " No diffs: open a real file instead of a scratch buffer
  let s:files = glob('PKGBUILD', 0, 1) + glob('*.PKGBUILD', 0, 1) + glob('*.SRCINFO', 0, 1)
  if empty(s:files)
    let s:files = filter(glob('*', 0, 1), 'filereadable(v:val)')
  endif
  if !empty(s:files)
    execute 'edit' fnameescape(s:files[0])
  endif
endif

NERDTree
NERDTreeFocus
let @/ = 'diff'
call search(@/, 'w')
set hlsearch

" ZZ quits immediately; any extra Z from a triple-tap is drained here / in the
" wrapper — no timeoutlen wait on a normal double-tap.
nnoremap ZZ :call <SID>ParuQuit(0)<CR>
nnoremap ZQ :call <SID>ParuQuit(1)<CR>
" If the file is closed first, don't leave a lonely NERDTree behind.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | q | endif

function! s:ParuQuit(force) abort
  " Brief drain so a third Z typed with ZZ doesn't leak to paru.
  let l:until = reltimefloat(reltime()) + 0.12
  while reltimefloat(reltime()) < l:until
    let l:c = getchar(0)
    if l:c is# 0
      sleep 10m
      continue
    endif
    " Got a key — keep draining a bit longer in case of more
    let l:until = reltimefloat(reltime()) + 0.08
  endwhile
  if a:force
    qa!
  else
    wqa
  endif
endfunction

redraw!
