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
set updatetime=300

"" Plugins
call plug#begin('~/.config/nvim/plugged')
" Statusline
Plug 'itchyny/lightline.vim'
" fzf
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" CoC
Plug 'neoclide/coc.nvim', {'branch': 'release'}
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
" Fix italic for sonokai
"highlight Comment cterm=italic
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ }

" disable preview fzf
let g:fzf_preview_window = []

" Key bindings
let mapleader=" "
nnoremap <C-r> :so ~/.config/nvim/init.vim<CR>
inoremap jj <ESC>
nnoremap <silent> <Leader><tab> :bnext<CR>

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
nnoremap <Leader>p :Files<CR>
nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>bd :bd<CR>


" Coc keybindings
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
