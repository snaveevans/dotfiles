if status is-interactive
    # Commands to run in interactive sessions can go here
end

function list_branches
  git branch 2>/dev/null | fzf | sed -n '/\* /s///p'
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

bind --user \cf forward-word
bind --user \cb backward-word

bind --user \cl forward-char
bind --user \ch backward-char

bind --user --key nul end-of-line 

bind --user \cg list_branches
bind --user \co nvim

[ -f /usr/local/share/autojump/autojump.fish ]; and source /usr/local/share/autojump/autojump.fish