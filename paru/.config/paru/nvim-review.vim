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

" ZZ/ZQ quit the whole review. Handled manually so ZZ never hangs waiting for
" a third Z (ambiguous ZZ/ZZZ maps + timeout caused that). Extra Z already in
" the queue (from a fast ZZZ) is dropped; we do not wait, so Enter reaches paru.
nnoremap <silent> Z :<C-u>call <SID>ParuZLeader()<CR>

function! s:ParuChar(c) abort
  return type(a:c) == v:t_number ? nr2char(a:c) : a:c
endfunction

function! s:ParuAbsorbQueuedZ() abort
  while 1
    let l:c = getchar(0)
    if l:c is# 0
      break
    endif
    let l:ch = s:ParuChar(l:c)
    if l:ch ==# 'Z' || l:ch ==# 'z'
      continue
    endif
    break
  endwhile
endfunction

function! s:ParuZLeader() abort
  let l:ch = s:ParuChar(getchar())
  if l:ch ==# 'Q'
    call s:ParuAbsorbQueuedZ()
    qa!
    return
  endif
  if l:ch !=# 'Z'
    call feedkeys('Z' . l:ch, 'in!')
    return
  endif
  call s:ParuAbsorbQueuedZ()
  wqa
endfunction

" If the file is closed first, don't leave a lonely NERDTree behind.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | q | endif

redraw!
