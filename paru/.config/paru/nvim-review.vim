" paru PKGBUILD review only — sourced via FileManagerFlags (-S)
" Wider NERDTree, open first *.diff, place tree cursor on it.
" (Do not set columns/lines — that corrupts the TUI with lightline.)

let g:NERDTreeWinSize = 45

" Replace the directory buffer with a real file so opens work on first click.
if argc() && isdirectory(expand(argv(0)))
  silent! bwipeout!
endif

let s:diffs = glob('*.diff', 0, 1)
if empty(s:diffs)
  let s:diffs = glob('**/*.diff', 0, 1)
endif

if !empty(s:diffs)
  execute 'keepalt edit' fnameescape(s:diffs[0])
else
  enew
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
endif

NERDTree
NERDTreeFocus
let @/ = 'diff'
call search(@/, 'w')
set hlsearch
redraw!
