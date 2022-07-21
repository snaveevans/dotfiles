if status is-interactive
    # Commands to run in interactive sessions can go here
end

# remove fish_greeting
set fish_greeting

function kill_process
  set -l process_id (ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if test -z "$process_id"
    return
  end

  commandline --append "kill -9 $process_id"
  commandline --function 'end-of-line'
end

function kill_port
  set -l process_id (lsof -P -i TCP -s TCP:LISTEN | fzf -m | awk '{print $2}')

  if test -z "$process_id"
    return
  end

  commandline --append "kill -9 $process_id"
  commandline --function 'end-of-line'
end

function list_branches
  set -l selected (git branch 2>/dev/null | fzf | sed -r 's/^[ \t\*]*//')
  commandline --append "$selected"
  commandline --function 'end-of-line'
end

function git_current_branch
  git branch 2>/dev/null | sed -n '/\* /s///p'
end

function git_get_branch
  set -l branch (git config --global "$argv[1]")
  set -l exists (git branch | grep "$branch")

  if test -n "$exists"
    echo "$branch"
    return
  end

  set branch (git config --global "$argv[2]") 
  set exists (git branch | grep "$branch")

  if test -n "$exists"
    echo "$branch"
  end
end

function git_main_branch
  git_get_branch "init.defaultBranch" "alternative.defaultBranch"
end

function git_develop_branch
  git_get_branch "init.developBranch" "alternative.developBranch"
end

function re_source
  source ~/.config/fish/config.fish
  echo "reloaded fish config"
  commandline --function 'end-of-line'
end

bind --user \cf forward-word
bind --user \cb backward-word

bind --user \cl forward-char
bind --user \ch backward-char

bind --user --key nul end-of-line 

bind --user \cg list_branches
bind --user \co nvim
bind --user \ce re_source
bind --user \cko kill_port
bind --user \ckp kill_process

[ -f /usr/share/autojump/autojump.fish ]; and source /usr/share/autojump/autojump.fish
[ -f /usr/local/share/autojump/autojump.fish ]; and source /usr/local/share/autojump/autojump.fish

source $HOME/.config/fish/alias.fish
source $HOME/.config/fish/env.fish
[ -f $HOME/.config/fish/os-specific.fish ]; and source $HOME/.config/fish/os-specific.fish
