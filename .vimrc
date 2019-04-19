set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'easymotion/vim-easymotion'
Plugin 'jiangmiao/auto-pairs'
Plugin 'joshdick/onedark.vim'
Plugin 'leafgarland/typescript-vim'
Plugin 'mileszs/ack.vim'
Plugin 'omnisharp/omnisharp-vim'
Plugin 'prettier/vim-prettier'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/nerdcommenter'
Plugin 'thaerkh/vim-workspace'
"Plugin 'snaveevans/vim-workspace'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-fugitive'
Plugin 'valloric/youcompleteme'
Plugin 'vim-airline/vim-airline'
Plugin 'w0rp/ale'
Plugin 'junegunn/gv.vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
filetype plugin on

syntax on
colorscheme onedark
set number "show line numbers
set cursorline
set incsearch "incremental search for /
set list "for vertical line tabs
set listchars=tab:\|\ "show vertical line for tabs
set tabstop=4 "show tabs as 4 spaces
set shiftwidth=4
set directory^=$HOME/.vim/tmp// "set swap directory
set ssop-=options    " do not store global and local values in a session
set ssop-=folds      " do not store folds
set splitright
set splitbelow

"copy and paste to and from system
inoremap <C-v> <ESC>"+pa
vnoremap <C-c> "+y
vnoremap <C-d> "+d
vnoremap <Leader>a :call SearchSelectedText()<CR>
vnoremap // y/<C-R>"<CR>
" delete without yanking \d
nnoremap <leader>d "_d
vnoremap <leader>d "_d
" Contextual code actions (uses fzf, CtrlP or unite.vim when available)
nnoremap <Leader><Space> :OmniSharpGetCodeActions<CR>
" Run code actions with text selected in visual mode to extract method
xnoremap <Leader><Space> :call OmniSharp#GetCodeActions('visual')<CR>
"vim-workspace toggle workspace
nnoremap <leader>s :ToggleWorkspace<CR>
nnoremap <Leader>a :Ack!<Space>
nnoremap th  :tabfirst<CR>
nnoremap tk  :tabnext<CR>
nnoremap tj  :tabprev<CR>
nnoremap tl  :tablast<CR>
nnoremap tt  :tabedit<Space>
nnoremap tn  :tabnext<Space>
nnoremap tm  :tabm<Space>
nnoremap td  :tabclose<CR>
nnoremap ty  :tabonly<CR>

nnoremap ,o  :CtrlPBuffer<CR>
nnoremap ,p  :CtrlP<CR>
nnoremap ,t  :CtrlPTag<CR>
nnoremap ,rr  :YcmCompleter RefactorRename<Space>
nnoremap ,rf  :YcmCompleter FixIt<CR>
nnoremap ,rw  :YcmCompleter OrganizeImports<CR>
nnoremap ,gt  :ALEGoToDefinition<CR>
nnoremap ,af  :ALEFix<CR>
nnoremap ,an  :ALENext<CR>
nnoremap ,ap  :ALEPrevious<CR>
nnoremap ,fr  :ALEFindReferences<CR>
nnoremap ,ch  :CloseHiddenBuffers<CR>
nnoremap ,qq  :q<CR>
nnoremap ,qa  :qa<CR>
nnoremap ,bd  :bd<CR>
nnoremap ,ww  :w<CR>
nnoremap ,wa  :wa<CR>
nnoremap ,wq  :wq<CR>
nnoremap ,st  :Gstatus<CR>
nnoremap ,gd  :Gdiff<CR>
nnoremap ,gc  :Gcommit<CR>
nnoremap ,gp  :Gpush<CR>
nnoremap ,gw  :Gwrite<CR>
nnoremap ,gf @z
nnoremap ,gh @x
"nnoremap ,te @c
nnoremap ,d  <C-f>
nnoremap ,u  <C-b>
nnoremap ,h  <C-w>h
nnoremap ,l  <C-w>l
vnoremap ,h  <C-w>h
vnoremap ,l  <C-w>l
nnoremap ,j  <C-w>j
nnoremap ,k  <C-w>k
vnoremap ,j  <C-w>j
vnoremap ,k  <C-w>k
nnoremap <leader>h  <C-w>h
nnoremap <leader>j  <C-w>j
nnoremap <leader>k  <C-w>k
nnoremap <leader>l  <C-w>l
"nnoremap ,wn :botright vnew<Space>
vnoremap ,f <ESC>/\%V
"easy motion word
"map ,a <Plug>(easymotion-bd-w)
"easy motions line
"map ,a <Plug>(easymotion-bd-jk) 
nnoremap ,aa _
vnoremap ,aa _
nnoremap ,ss g_
vnoremap ,ss g_

"open nerd tree with ctrl+n
map <C-n> :NERDTreeToggle<CR>
map <leader>f :NERDTreeFind<CR>
"open nerdtree when opening directory
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif
let @z='_/:wv$h"ay:tabnew a:Gdiff'
let @x='_/:wvg_"hy:tabnew h'
let @c='_/''lvnh"ny:tabe %:h/n'
"ignore fils in gitignore with CtrlP
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
let NERDTreeShowHidden=1 "show hidden files in nerd tree
let g:ctrlp_show_hidden = 1 "show hidden files in CtrlP
let g:airline#extensions#tabline#tab_nr_type = 1 "show tab number using airline
let g:ycm_filetype_blacklist = { 'cs': 1 }
let g:ycm_autoclose_preview_window_after_insertion = 1 "auto-close preview window in YCM
let g:OmniSharp_server_use_mono = 1
let g:OmniSharp_selector_ui = 'ctrlp'  " Use ctrlp.vim
"let g:OmniSharp_proc_debug = 1
"let g:OmniSharp_loglevel = 'debug'
let g:ale_linters = { 'cs': ['OmniSharp'] }
let g:ale_fixers = { 'javascript': ['eslint', 'prettier'], 'typescript': ['tslint', 'prettier'], 'cs': ['OmniSharp'] }
let g:ale_completion_enabled = 1
let g:airline#extensions#ale#enabled = 1
let g:workspace_autosave = 0 "disable autosave
"let g:workspace_session_name = 'Session.vim'
let g:workspace_session_directory = $HOME . '/.vim/sessions/'
let g:workspace_persist_undo_history = 0
"let g:ycm_log_level='debug'
let g:prettier#exec_cmd_async = 1
let g:prettier#autoformat = 0
let g:prettier#exec_cmd_path = '/usr/local/bin/prettier'
autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue PrettierAsync

"open CtrlP files in new tab
let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<c-t>'],
    \ 'AcceptSelection("t")': ['<cr>', '<2-LeftMouse>'],
    \ }
let g:ctrlp_buftag_types = {
\ 'typescript' : {
  \ 'bin': 'ctags',
  \ 'args': '-f - ',
  \ },
\ 'javascript' : {
  \ 'bin': 'ctags',
  \ 'args': '-f - ',
  \ }
\ }
"let g:ctrlp_buftag_types = { 
	"\ 'javascript': '--language-force=javascript',
	"\ 'typescript': '--language-force=typescript'
	"\ }
"airline tabs enabled
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

function! GetVisual() range 
	let reg_save = getreg('"') 
	let regtype_save = getregtype('"') 
	let cb_save = &clipboard 
	set clipboard& 
	normal! ""gvy 
	let selection = getreg('"') 
	call setreg('"', reg_save, regtype_save) 
	let &clipboard = cb_save 
	return selection
endfunction

function! SearchSelectedText() range
	let selection = GetVisual()
	execute printf('Ack! "%s"', selection)
endfunction

command! -nargs=1 RR YcmCompleter RefactorRename <args>
command! -nargs=0 RF YcmCompleter FixIt
command! -nargs=0 AF ALEFix
command! -nargs=0 FR ALEFindReferences
command! -nargs=0 GT ALEGoToDefinition
command! -nargs=0 RW YcmCompleter OrganizeImports
command! -nargs=0 DF YcmCompleter OrganizeImports | Prettier
command! -nargs=0 PP Prettier
command! -nargs=0 QQ CloseHiddenBuffers 
command! -nargs=0 UP bufdo e! "command will discard changes and reload files
command! -nargs=0 JK bd

