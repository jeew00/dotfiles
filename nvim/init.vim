"" Some basic settings
filetype plugin indent on
syntax on
set wildmenu
set hidden
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set autoindent
set noswapfile
set nobackup
set nu
set relativenumber
set nohlsearch
set hidden
set noerrorbells
set noswapfile
set incsearch
set scrolloff=8
set termguicolors
set noshowmode
set colorcolumn=80
set signcolumn=yes
set scrolloff=8
set cmdheight=2
set cursorline
set nowrap
set clipboard=unnamed

"" Plugins
call plug#begin('~/.config/nvim/plugged')
" Files navigation with telescope
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
" Statusline
Plug 'vim-airline/vim-airline'
" deoplete
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'deoplete-plugins/deoplete-jedi'
" Comment Toggle
Plug 'preservim/nerdcommenter'
" colorscheme
Plug 'sainnhe/sonokai'
call plug#end()

" Activate colorscheme
colorscheme sonokai
hi Normal ctermbg=none guibg=none
hi NonText ctermbg=none guibg=none guifg=none ctermfg=none

" Key bindings
let mapleader=" "
nnoremap <C-m> :so ~/.config/nvim/init.vim<CR>


" Key bindings
let mapleader=" "
nnoremap <C-m> :so ~/.config/nvim/init.vim<CR>
inoremap jj <ESC>
nnoremap <silent> <C-p> :Telescope find_files<CR>

" deoplete
let g:deoplete#enable_at_startup = 1
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"

" nerdcommenter configs
let g:NERDCreateDefaultMappings = 0
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
nnoremap <Leader>/ :call NERDComment('n', 'toggle')<CR>
vnoremap <Leader>/ :call NERDComment('x', 'toggle')<CR>  
