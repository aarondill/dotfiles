" Set leader key. Any references must be after!
let mapleader = ','

" Map Y to act like D and C, i.e. to yank until EOL, rather than act as yy,
" which is the default
map Y y$
" Map <C-L> (redraw screen) to also turn off search highlighting until the
" next search
nnoremap <C-L> :nohl<CR><C-L>

" Change z key in normal mode to undo and Z to redo
nnoremap z u
nnoremap Z <C-r>

" Paste system clipboard with Ctrl + v
inoremap <C-v> <C-r>+
nnoremap <C-v> "+gP<ESC>
vnoremap <C-v> d"+gP<ESC>
cnoremap <C-v> <C-r>+

" Cut to system clipboard with Ctrl + x
vnoremap <C-x> "+d
nnoremap <C-x> "+dd
inoremap <C-x> <ESC>"+ddi

" Copy to system clipboard with Ctr + c
vnoremap <C-c> "+y
nnoremap <C-c> "+yy
inoremap <C-c> <ESC>"+yyi

" Quick quit
nnoremap <C-k> :q<cr>
" Terminal allow escape to exit insert
tnoremap <Esc> <C-\><C-n>
