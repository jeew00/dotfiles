" Some basic settings
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
set clipboard=unnamedplus

"" Plugins
call plug#begin('~/.config/nvim/plugged')
" Statusline
Plug 'itchyny/lightline.vim'
" fzf
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" deoplete
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'deoplete-plugins/deoplete-jedi'
" Comment Toggle
Plug 'preservim/nerdcommenter'
" NERDTree
Plug 'preservim/nerdtree'
" colorscheme
Plug 'sainnhe/sonokai'
call plug#end()

" Activate colorscheme
colorscheme sonokai
hi Normal guibg=none ctermbg=none
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ }

" Key bindings
let mapleader=" "
nnoremap <C-r> :so ~/.config/nvim/init.vim<CR>
inoremap jj <ESC>

" deoplete
let g:deoplete#enable_at_startup = 1
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"

" nerdcommenter configs
let g:NERDCreateDefaultMappings = 0
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
nnoremap <Leader>/ :call NERDComment('n', 'toggle')<CR>
vnoremap <Leader>/ :call NERDComment('x', 'toggle')<CR>  

" NERDTree configs
nnoremap <Leader>t :NERDTreeToggle<CR>
let g:NERDTreeMapCustomOpen = '<tab>'

" fzf keybindings
nnoremap <Leader>p :Files 
nnoremap <Leader>ps :Files<CR>
nnoremap <Leader>bf :Buffers<CR>
