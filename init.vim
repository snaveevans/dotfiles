" Turn on the Wild menu
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

"======================================================================
" => Visual mode related
"======================================================================
" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>


"======================================================================
" => Moving around, tabs, windows and buffers
"======================================================================
" Easy tab movement in normal mode
map <silent> th  :tabfirst<CR>
map <silent> tk  :tabnext<CR>
map <silent> tj  :tabprev<CR>
map <silent> tl  :tablast<CR>
map tt  :tabedit<Space>
map tm  :tabmove<Space>
map <silent> td  :tabclose<CR>
map <silent> ty  :tabonly<CR>

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <leader>tl :exe "tabn ".g:lasttab<CR>
au TabLeave * let g:lasttab = tabpagenr()


" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

"======================================================================
" => Helper functions
"======================================================================

function! SaveLastReg()
    if v:event['regname']==""
        if v:event['operator']=='y'
            for i in range(8,1,-1)
                exe "let @".string(i+1)." = @". string(i) 
            endfor
            if exists("g:last_yank")
                let @1=g:last_yank
            endif
            let g:last_yank=@"
        endif 
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
		call CmdLine("Rg '" . l:pattern . "' " )
	elseif a:direction == 'replace'
		call CmdLine("%s" . '/'. l:pattern . '/')
	endif

	let @/ = l:pattern
	let @" = l:saved_reg
endfunction

function! SaveSession(force)
  if (filereadable("Session.vim") || a:force)
    execute printf('mksession! %s/%s', getcwd(), 'Session.vim')
    echo "Saved Session"
  endif
endfunction
function! LoadSession()
  execute 'source ' . 'Session.vim'
endfunction

"======================================================================
" => Plugin Configuration
"======================================================================

"======================================================================
" => Netrw

let g:netrw_banner = 0
let g:netrw_liststyle = 1
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25
let g:netrw_keepdir = 0
hi! link netrwMarkFile Search

augroup NetrwCommands
	autocmd!
	" Ensure netrw doesn't open
	autocmd VimEnter * silent! au! FileExplorer
augroup END


"======================================================================
" => itchyny/lightline.vim

let g:lightline = {
      \ 'colorscheme': 'one',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'relativepath', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'FugitiveHead'
      \ },
      \ }

"======================================================================
" => Fzf

" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1
" - Popup window (anchored to the bottom of the current window)
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6, 'yoffset': 1.0 } }
let g:fzf_preview_window = ['right:50%', 'ctrl-/']

nnoremap <silent> <Leader>p :Files<CR>
nnoremap <silent> <Leader>P :AllFiles<CR>
nnoremap <silent> <Leader>l :Files <c-r>=expand("%:p:h")<cr>/<CR>
nnoremap <silent> <Leader>o :Buffers<CR>
nnoremap <silent> <c-space> :Buffers<CR>
nnoremap <silent> <Leader>ft :Filetypes<CR>
nnoremap <silent> <Leader>m :Maps<CR>
nnoremap <silent> <Leader>/ :BLines<CR>
nnoremap <silent> <Leader>' :Marks<CR>
nnoremap <silent> <Leader>g :Commits<CR>
nnoremap <silent> <Leader>H :Helptags<CR>
nnoremap <silent> <Leader>hh :History<CR>
nnoremap <silent> <Leader>h: :History:<CR>
nnoremap <silent> <Leader>h/ :History/<CR>

let g:fzf_action = {
  \ 'ctrl-space': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

nnoremap <silent> <leader>s  :Rg <CR>
nnoremap <silent> <leader>S  :Rg 
vnoremap <silent> <leader>s :<C-u>call VisualSelection('', '')<CR>:Rg <C-R>=@/<CR><CR>
vnoremap <silent> <leader>fa :<C-u>call VisualSelection('', '')<CR>:Rg <C-R>=@/<CR><CR>
vnoremap <silent> <leader>fe :<C-u>call VisualSelection('', '')<CR>:Rg \b<C-R>=@/<CR>\b<CR>
nmap <silent> <leader>fa :Rg <C-r>=expand("<cword>")<CR><CR>
nmap <silent> <leader>fe :Rg \b<C-r>=expand("<cword>")<CR>\b<CR>

command! -bang -nargs=? -complete=dir Files
      \ call fzf#vim#files(<q-args>, {'source': 'rg --files --hidden --follow --glob=\!.git'}, <bang>0)

command! -bang -nargs=? -complete=dir AllFiles
      \ call fzf#vim#files(<q-args>, {'source': 'rg --files --hidden --follow --no-ignore'}, <bang>0)

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>),
  \   1,
  \   fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}), <bang>0)
" set internal grep to use rg
set grepprg=rg\ --vimgrep\ --smart-case\ --follow

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

"======================================================================
" => Misc
" save last reg into the next reg
au! TextYankPost * call SaveLastReg()

au! VimLeave * call SaveSession(0)
nnoremap <silent> <F5> :call SaveSession(1)<CR>
nnoremap <silent> <F8> :call LoadSession()<CR>

" find & replace
vnoremap <leader>fr :<C-u>call VisualSelection('', '')<CR>:%s/<C-R>=@/<CR>/
