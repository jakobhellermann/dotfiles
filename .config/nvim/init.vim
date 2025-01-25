call plug#begin('~/.config/nvim/plugged')

Plug 'airblade/vim-gitgutter'

Plug 'lotabout/skim', { 'dir': '~/.skim', 'do': './install' }
Plug 'lotabout/skim.vim'
Plug 'tpope/vim-surround'

" Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

colorscheme wildcharm
highlight Normal guibg=NONE ctermbg=NONE
highlight NonText guibg=NONE ctermbg=NONE

" autocmds
autocmd BufNewFile,BufRead .aliases*,.env* set syntax=sh
autocmd Filetype rust set signcolumn=yes
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd BufNewFile,BufRead *.tsx set filetype=typescript
autocmd BufNewFile,BufRead *.conf set filetype=texmf
autocmd BufNewFile,BufRead *.wgsl set filetype=wgsl

" behaviour
set updatetime=400
" set ttimeoutlen=5

set undodir=/tmp/nvim-undo-dir
set undofile

set autoindent
set noexpandtab
set tabstop=4
set shiftwidth=4

set wildmenu
set wildmode=longest:full,full
set wildignore=*.swp,.git/*

set incsearch
set smartcase
set gdefault
set ignorecase

" ui 
set number
set ruler
set nowrap
" highlight LineNr ctermbg=None
" highlight CursorLineNr ctermbg=None

""" KEYBINGINGS
let mapleader = "\," 

nno <Leader>w :w<CR>
nno <Leader>x :x<CR>
nno <Leader>q :q<CR>
nno <Leader>r :so $MYVIMRC<CR>

" system keyboard
vmap <Leader>y "+y

" ,, for buffer switching
nno <leader><leader> <c-^> 

" center search results
nno <silent> n nzz
nno <silent> N Nzz
nno <silent> * *zz
nno <silent> # #zz
nno <silent> g* g*zz

""" PLUGIN SETTINGS
" gitgutter
nmap 88 <Plug>(GitGutterPrevHunk)
nmap 99 <Plug>(GitGutterNextHunk)

" skim
nmap <Leader>f :Files<CR>
nmap <Leader>g :GFiles<CR>
nmap <Leader>b :Buffers<CR>

set nowrap
