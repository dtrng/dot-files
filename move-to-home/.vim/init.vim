" Vundle settings
set nocompatible
filetype off

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'tpope/vim-surround'
Plugin 'scrooloose/syntastic'
Plugin 'tpope/vim-fugitive'
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

" END OF VUNDLE settings

let mapleader = ','

let g:syntastic_javascript_checkers = ['eslint']
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

set number
set relativenumber
filetype plugin indent on
syntax on
set cursorline
"hi CursorLine cterm=NONE ctermbg=52 guibg=#5f0000 
set shiftwidth=2
set tabstop=2
set expandtab
"set clipboard=unnamed
"set clipboard+=unnamed
set showmatch

" nerdtree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
"map <C-n> :NERDTreeToggle<CR>
map <Leader>k :NERDTreeToggle<CR>

imap jj <ESC>

" moving between splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

set smartcase
"nmap <S-W> :w
"nmap <S-Q> :q
set timeoutlen=1000 ttimeoutlen=0


set backspace=indent,eol,start
