" Setup neovim to use vimrc
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
if filereadable(expand('~/.vimrc'))
    source ~/.vimrc
elseif filereadable(expand('~/.vim/vimrc'))
    source ~/.vim/vimrc
endif
lua <<EOF
require('tabnine').setup({
  disable_auto_comment=true,
  accept_keymap="<Tab>",
  dismiss_keymap = "<C-]>",
  debounce_ms = 800,
  suggestion_color = {gui = "#808080", cterm = 244},
  exclude_filetypes = {"TelescopePrompt"}
})
EOF
