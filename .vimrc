
" Sections:
"    -> Plugins Installation
"    -> General
"    -> VIM user interface
"    -> Colors and Fonts
"    -> Files and backups
"    -> Text, tab and indent related
"    -> Visual mode related
"    -> Moving around, tabs and buffers
"    -> Status line
"    -> Editing mappings
"    -> vimgrep searching and cope displaying
"    -> Spell checking
"    -> Misc
"    -> Helper functions
"    -> Plugin Configuration
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins Installation
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Install vim-plug if it isn't
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')
" Make sure you use single quotes

Plug 'alvan/vim-closetag'
Plug 'easymotion/vim-easymotion'
Plug 'ervandew/supertab'
Plug 'jiangmiao/auto-pairs'
Plug 'joshdick/onedark.vim'
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/gv.vim'
Plug 'leafgarland/typescript-vim'
Plug 'omnisharp/omnisharp-vim'
Plug 'peitalin/vim-jsx-typescript'
Plug 'prettier/vim-prettier'
Plug 'thaerkh/vim-workspace'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'valloric/youcompleteme', { 'dir': '~/.vim/plugged/youcompleteme', 'do': './install.py --ts-completer' }
Plug 'vim-airline/vim-airline'
Plug 'w0rp/ale'
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif

" Initialize plugin system
call plug#end()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Sets how many lines of history VIM has to remember
set history=500

" Enable filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread

" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","

" Fast saving
nmap <leader>w :w!<cr>

" :W sudo saves the file
" (useful for handling the permission-denied error)
command W w !sudo tee % > /dev/null


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => VIM user interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set 3 lines to the cursor - when moving vertically using j/k
set so=3

" Enable syntax highlight
syntax on

" Show line numbers
set number

" Highlight line cursor is on
set cursorline

" For vertical line tabs
set list

" Show vertical line for tabs
set listchars=tab:\|\ 

" Set default splits
set splitright
set splitbelow
set diffopt+=vertical


" Avoid garbled characters in Chinese language windows OS
let $LANG='en'
set langmenu=en
source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim

" Turn on the Wild menu
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

"Always show current position
set ruler

" Height of the command bar
set cmdheight=2

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Properly disable sound on errors on MacVim
if has("gui_macvim")
    autocmd GUIEnter * set vb t_vb=
endif


" Add a bit extra margin to the left
set foldcolumn=1

set omnifunc=syntaxcomplete#Complete

" Omni complete select longest and always show
set completeopt=longest,menuone
inoremap <expr> <C-n> pumvisible() ? '<C-n>' :
  \ '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'

inoremap <expr> <M-,> pumvisible() ? '<C-n>' :
  \ '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Colors and Fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable syntax highlighting
syntax enable

" Enable 256 colors palette in Gnome Terminal
if $COLORTERM == 'gnome-terminal'
    set t_Co=256
endif

try
   " The best color scheme
   colorscheme onedark
catch
endtry

set background=dark

" Set extra options when running in GUI mode
if has("gui_running")
    set guioptions-=T
    set guioptions-=e
    set t_Co=256
    set guitablabel=%M\ %t
endif

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Files, backups and undo
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile

" This sets swap directory
" Set directory^=$HOME/.vim/tmp//
" Do not store global and local values in a session
set ssop-=options
" Do not store folds
set ssop-=folds


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Use spaces instead of tabs
" set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

" Linebreak on 500 characters
set lbr
set tw=500

set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines


""""""""""""""""""""""""""""""
" => Visual mode related
""""""""""""""""""""""""""""""
" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>
vnoremap <silent> <leader>a :<C-u>call VisualSelection('', '')<CR>:Ag <C-R>=@/<CR><CR>

"copy and cut to  system
vnoremap <C-c> "+y
vnoremap <C-d> "+d
" delete without yanking \d
vnoremap <leader><leader>d "_d


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Moving around, tabs, windows and buffers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Map <Space> to / (search) and Ctrl-<Space> to ? (backwards search)
map <space> /
map <c-space> ?

" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l
map <leader>j <C-W>j
map <leader>k <C-W>k
map <leader>h <C-W>h
map <leader>l <C-W>l

" Close the current buffer
map <leader>bd :bd<cr>
" map <leader>bd :Bclose<cr>:tabclose<cr>gT

" Close all the buffers
map <leader>ba :bufdo bd<cr>

" map <leader>l :bnext<cr>
" map <leader>h :bprevious<cr>

" Useful mappings for managing tabs
map tn :tabnew<cr>
map <leader>t<leader> :tabnext

" Easy tab movement in normal mode
map <silent> th  :tabfirst<CR>
map <silent> tk  :tabnext<CR>
map <silent> tj  :tabprev<CR>
map <silent> tl  :tablast<CR>
map tt  :tabedit<Space>
map tn  :tabnext<Space>
map tm  :tabmove<Space>
map <silent> td  :tabclose<CR>
map <silent> ty  :tabonly<CR>

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <leader>tl :exe "tabn ".g:lasttab<CR>
au TabLeave * let g:lasttab = tabpagenr()


" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
map <leader>tn :tabedit <c-r>=expand("%:p:h")<cr>/

" Move up & down the buffer easier
nnoremap <leader>d  <C-f>
nnoremap <leader>u  <C-b>

" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>

" Specify the behavior when switching between buffers
try
  set switchbuf=useopen,usetab,newtab
  set stal=2
catch
endtry

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

nnoremap <leader>z :sus<cr>


""""""""""""""""""""""""""""""
" => Status line
""""""""""""""""""""""""""""""
" Always show the status line
set laststatus=2

" Format the status line
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Editing mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Remap VIM 0 to first non-blank character
map 0 ^

" Move a line of text using ALT+[jk] or Command+[jk] on mac
nmap <M-j> mz:m+<cr>`z
nmap <M-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z

if has("mac") || has("macunix")
  nmap <D-j> <M-j>
  nmap <D-k> <M-k>
  vmap <D-j> <M-j>
  vmap <D-k> <M-k>
endif

" Delete trailing white space on save, useful for some filetypes ;)
fun! CleanExtraSpaces()
    let save_cursor = getpos(".")
    let old_query = getreg('/')
    silent! %s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfun

if has("autocmd")
    autocmd BufWritePre *.txt,*.js,*.py,*.wiki,*.sh,*.coffee :call CleanExtraSpaces()
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Spell checking
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Pressing ,ss will toggle and untoggle spell checking
map <leader>ss :setlocal spell!<cr>

" Shortcuts using <leader>
map <leader>sn ]s
map <leader>sp [s
map <leader>sa zg
map <leader>s? z=


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Misc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Remove the Windows ^M - when the encodings gets messed up
noremap <leader>m mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm

" Quickly open a buffer for scribble
map <leader>q :q<cr>

" Quickly open a markdown buffer for scribble
map <leader>x :e ~/buffer.md<cr>

" Toggle paste mode on and off
" map <leader>pp :setlocal paste!<cr>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Returns true if paste mode is enabled
function! HasPaste()
	if &paste
		return 'PASTE MODE  '
	endif
	return ''
endfunction

" Don't close window, when deleting a buffer
command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
	let l:currentBufNum = bufnr("%")
	let l:alternateBufNum = bufnr("#")

	if buflisted(l:alternateBufNum)
		buffer #
	else
		bnext
	endif

	if bufnr("%") == l:currentBufNum
		new
	endif

	if buflisted(l:currentBufNum)
		execute("bdelete! ".l:currentBufNum)
	endif
endfunction

function! CmdLine(str)
	call feedkeys(":" . a:str)
endfunction

function! VisualSelection(direction, extra_filter) range
	let l:saved_reg = @"
	execute "normal! vgvy"

	let l:pattern = escape(@", "\\/.*'$^~[]")
	let l:pattern = substitute(l:pattern, "\n$", "", "")

	if a:direction == 'gv'
		call CmdLine("Ag '" . l:pattern . "' " )
	elseif a:direction == 'replace'
		call CmdLine("%s" . '/'. l:pattern . '/')
	endif

	let @/ = l:pattern
	let @" = l:saved_reg
endfunction

function DeleteHiddenBuffers()
	let tpbl=[]
	call map(range(1, tabpagenr('$')), 'extend(tpbl, tabpagebuflist(v:val))')
	for buf in filter(range(1, bufnr('$')), 'bufexists(v:val) && index(tpbl, v:val)==-1')
		silent execute 'bwipeout' buf
	endfor
endfunction

function EnableDisableDeoplete()
	let enabledFileTypes = ['cs']
	if index(enabledFileTypes, &ft) >= 0
		" enable deoplete
		call deoplete#custom#buffer_option('auto_complete', v:true)
	else
		" disable deoplete
		call deoplete#custom#buffer_option('auto_complete', v:false)
	endif
endfunction

function! AngularOpenComponent()
	let l:files = split(globpath(expand("%:p:h"), "*"), "\n")
	let l:componentFile = filter(deepcopy(l:files), function("FilterComponentFile", [".component.ts"]))
	if len(l:componentFile) >= 1
		execute "edit ".fnameescape(l:componentFile[0])
	endif
	let l:markupFile = filter(deepcopy(l:files), function("FilterComponentFile", [".html"]))
	if len(l:markupFile ) >= 1
		execute "vsplit ".fnameescape(l:markupFile[0])
	endif
	let l:styleFile = filter(deepcopy(l:files), function("FilterComponentFile", [".scss"]))
	if len(l:styleFile) >= 1
		execute "vsplit ".fnameescape(l:styleFile[0])
	endif
	execute("wincmd =")
	execute("wincmd h")
	execute("wincmd h")
endfunction

function! FilterComponentFile(desiredFile, idx, filePath)
	if a:filePath =~ a:desiredFile
		return 1
	else
		return 0
	endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Netrw
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25
augroup NetrwCommands
	autocmd!
	" Open Explorer
	nnoremap <silent> <leader>e :Vexplore<cr>

	" Open Explorer in new Tab
	nnoremap <silent> <leader>n :Texplore<cr>
	" Open netrw as side drawer
	" autocmd VimEnter * :Vexplore

	" Ensure netrw doesn't open
	autocmd VimEnter * silent! au! FileExplorer
augroup END

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => deoplete
let g:deoplete#enable_at_startup = 1
autocmd BufEnter * call EnableDisableDeoplete()
call deoplete#custom#source('omni', 'functions', {
    \ 'csharp':  'omnisharp',
    \})
" let g:deoplete#sources#ts = {'_': ['ale']}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-workspace
" Toggle workspace
nnoremap <leader>s :ToggleWorkspace<CR>
" Close all hidden buffers
" nnoremap <leader>ch  :CloseHiddenBuffers<CR>
" Disable autosave
let g:workspace_autosave = 0 
"let g:workspace_session_name = 'Session.vim'
let g:workspace_session_directory = $HOME . '/.vim/sessions/'
let g:workspace_persist_undo_history = 0

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Fzf
nnoremap <leader>p  :Files<CR>
nnoremap <leader>o  :Buffers<CR>
" nnoremap <leader>t  :Tags<CR>
nnoremap <leader>a  :Ag<CR>
" search selected text using :Ack
" vnoremap <leader>a :call SearchSelectedText()<CR>
command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, {'options': '--delimiter : --nth 4..'}, <bang>0)

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => ALE
nnoremap gd  :ALEGoToDefinition<CR>
nnoremap <leader>af  :ALEFix<CR>
nnoremap <leader>an  :ALENext<CR>
nnoremap <leader>ap  :ALEPrevious<CR>
nnoremap <leader>fr  :ALEFindReferences<CR>
" Tell ALE to use OmniSharp for linting C# files, and no other linters.
let g:ale_linters = { 'cs': ['OmniSharp'] }
let g:ale_fixers = { 
\ 'javascript': ['eslint', 'prettier'], 
\ 'typescript': ['tslint', 'prettier'], 
\ }
" let g:ale_completion_enabled = 1
command! -nargs=0 AF ALEFix
command! -nargs=0 FR ALEFindReferences
command! -nargs=0 GT ALEGoToDefinition


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-fugitive
nnoremap <leader>st  :Gstatus<CR>
nnoremap <leader>gd  :Gdiff<CR>
nnoremap <leader>gc  :Gcommit<CR>
nnoremap <leader>gp  :Gpush<CR>
nnoremap <leader>gw  :Gwrite<CR>

" macro to open file from GStatus in new tab
nnoremap <leader>gh @x
let @x='_wvg_"hy:tabnew h'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => airline
" Show tab number using airline
let g:airline#extensions#tabline#tab_nr_type = 1
" Airline tabs enabled
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#ale#enabled = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Prettier
nnoremap <leader>fd  :Prettier<CR>
" Always execute async
" let g:prettier#exec_cmd_async = 1
let g:prettier#autoformat = 0
let g:prettier#exec_cmd_path = '/usr/local/bin/prettier'
" Trigger PrettierAsync before writing buffer
autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.html PrettierAsync
command! -nargs=0 PP Prettier

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => SuperTab
" Map SuperTab up & down to k & j
let g:SuperTabMappingForward = '<c-k>'
let g:SuperTabMappingBackward = '<c-j>'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => YouCompleteMe
augroup ycm_commands
    autocmd!

    autocmd FileType typescript nnoremap <buffer> <leader>rr  :YcmCompleter RefactorRename<Space>
    autocmd FileType typescript nnoremap <buffer> <leader>fi  :YcmCompleter FixIt<CR>
    autocmd FileType typescript nnoremap <buffer> <leader>rw  :YcmCompleter OrganizeImports<CR>

    autocmd FileType javascript nnoremap <buffer> <leader>rr  :YcmCompleter RefactorRename<Space>
    autocmd FileType javascript nnoremap <buffer> <leader>fi  :YcmCompleter FixIt<CR>
    autocmd FileType javascript nnoremap <buffer> <leader>rw  :YcmCompleter OrganizeImports<CR>
augroup END
" Dont use ycm for c# files
let g:ycm_filetype_blacklist = { 'cs': 1 }
" Auto-close preview window in YCM
let g:ycm_autoclose_preview_window_after_insertion = 1
"let g:ycm_log_level='debug'
" command! -nargs=1 RR YcmCompleter RefactorRename <args>
" command! -nargs=0 RF YcmCompleter FixIt
" command! -nargs=0 RW YcmCompleter OrganizeImports

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Omnisharp
let g:OmniSharp_server_use_mono = 1
" let g:OmniSharp_selector_ui = 'ctrlp'  " Use ctrlp.vim
let g:OmniSharp_server_path = '/Users/tyler/omnisharp.http-osx/omnisharp/OmniSharp.exe'

" Fetch semantic type/interface/identifier names on BufEnter and highlight them
let g:OmniSharp_highlight_types = 1

augroup omnisharp_commands
    autocmd!

    " Show type information automatically when the cursor stops moving
    autocmd CursorHold *.cs call OmniSharp#TypeLookupWithoutDocumentation()

    " Update the highlighting whenever leaving insert mode
    autocmd InsertLeave *.cs call OmniSharp#HighlightBuffer()

    " Alternatively, use a mapping to refresh highlighting for the current buffer
    autocmd FileType cs nnoremap <buffer> <leader>th :OmniSharpHighlightTypes<CR>

    " The following commands are contextual, based on the cursor position.
    autocmd FileType cs nnoremap <buffer> gd :OmniSharpGotoDefinition<CR>
    autocmd FileType cs nnoremap <buffer> <leader>fi :OmniSharpFindImplementations<CR>
    autocmd FileType cs nnoremap <buffer> <leader>fs :OmniSharpFindSymbol<CR>
    autocmd FileType cs nnoremap <buffer> <leader>fu :OmniSharpFindUsages<CR>

    " Finds members in the current buffer
    autocmd FileType cs nnoremap <buffer> <leader>fm :OmniSharpFindMembers<CR>

    autocmd FileType cs nnoremap <buffer> <leader>fx :OmniSharpFixUsings<CR>
    autocmd FileType cs nnoremap <buffer> <leader>tt :OmniSharpTypeLookup<CR>
    autocmd FileType cs nnoremap <buffer> <leader>dc :OmniSharpDocumentation<CR>
    autocmd FileType cs nnoremap <buffer> <C-\> :OmniSharpSignatureHelp<CR>
    autocmd FileType cs inoremap <buffer> <C-\> <C-o>:OmniSharpSignatureHelp<CR>

    " Navigate up and down by method/property/field
    autocmd FileType cs nnoremap <buffer> <leader>k :OmniSharpNavigateUp<CR>
    autocmd FileType cs nnoremap <buffer> <leader>j :OmniSharpNavigateDown<CR>

    " Formate the buffer
    autocmd FileType cs nnoremap <buffer> <leader>fd :OmniSharpCodeFormat<CR>

    " Contextual code actions (uses fzf, CtrlP or unite.vim when available)
    autocmd FileType cs nnoremap <buffer> <leader><Space> :OmniSharpGetCodeActions<CR>
    " Run code actions with text selected in visual mode to extract method
    autocmd FileType cs xnoremap <buffer> <leader><Space> :call OmniSharp#GetCodeActions('visual')<CR>

    " Rename with dialog
    autocmd FileType cs nnoremap <buffer> <leader>rr :OmniSharpRename<CR>
    " Rename without dialog - with cursor on the symbol to rename: `:Rename newname`
    autocmd FileType cs command! -nargs=1 Rename :call OmniSharp#RenameTo("<args>")

    " Start the omnisharp server for the current solution
    autocmd FileType cs nnoremap <buffer> <leader>ss :OmniSharpStartServer<CR>
    autocmd FileType cs nnoremap <buffer> <leader>sp :OmniSharpStopServer<CR>
    
    " Map ctrl-space to open omnicomplete
    autocmd FileType cs inoremap <buffer> <C-Space> <C-x><C-o>
augroup END

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-jsx-typescript
" Set filetypes js & ts as typescript.tsx
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescript.tsx

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-closetag

let g:closetag_filenames = '*.html,*.xhtml,*.phtml'
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.tsx'
let g:closetag_filetypes = 'html,xhtml,phtml'
let g:closetag_xhtml_filetypes = 'xhtml,jsx,tsx'
let g:closetag_emptyTags_caseSensitive = 1
let g:closetag_regions = {
    \ 'typescript.tsx': 'jsxRegion,tsxRegion',
    \ 'javascript.jsx': 'jsxRegion',
    \ }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Misc
" paste from system
inoremap <C-v> <ESC>"+pa
" delete without yanking \d
nnoremap <leader><leader>d "_d
" Unknown macro
" nnoremap <leader>te @c
" let @c='_/''lvnh"ny:tabe %:h/n'

" Diff get target
" map <leader>dgt :diffget //2 | diffupdate<cr>

" Diff get merge
" map <leader>dgm :diffget //3 | diffupdate<cr>

" Open angular component
nnoremap <leader>ao :call AngularOpenComponent()<CR>

" Open Component
vnoremap <silent> <leader>a :<C-u>call VisualSelection('', '')<CR>:Ag <C-R>=@/<CR><CR>

" Close Hidden Buffers
nnoremap <leader>ch :call DeleteHiddenBuffers()<CR>

command! -nargs=0 UP bufdo e! "command will discard changes and reload files
command! -nargs=0 JK bd
command! -nargs=0 AngularOpenComponent call AngularOpenComponent()

"nnoremap ,h  <C-w>h
"nnoremap ,l  <C-w>l
"vnoremap ,h  <C-w>h
"vnoremap ,l  <C-w>l
"nnoremap ,j  <C-w>j
"nnoremap ,k  <C-w>k
"vnoremap ,j  <C-w>j
"vnoremap ,k  <C-w>k
"nnoremap <leader>h  <C-w>h
"nnoremap <leader>j  <C-w>j
"nnoremap <leader>k  <C-w>k
"nnoremap <leader>l  <C-w>l
"nnoremap ,wn :botright vnew<Space>
"vnoremap , <ESC>/\%V

