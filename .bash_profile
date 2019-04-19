export PS1="\[\033[36m\]\u\[\033[33m\]@\[\033[35m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
alias ls='ls -GFh'
alias ll='ls -l'
alias vim='/Applications/MacVim.app/Contents/MacOS/Vim'
alias mvim='/Applications/MacVim.app/Contents/MacOS/Vim -g'
ASPNETCORE_ENVIRONMENT=Development
ASPNETCORE_HTTPS_PORT=5001
export NODE_ENV=development
export JAVA_HOME=`/Users/tylerevans/bin/jdk/Contents/Home/bin/java`


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/tylerevans/bin/google-cloud-sdk/path.bash.inc' ]; then source '/Users/tylerevans/bin/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/tylerevans/bin/google-cloud-sdk/completion.bash.inc' ]; then source '/Users/tylerevans/bin/google-cloud-sdk/completion.bash.inc'; fi

# Setting PATH for Python 3.7
# The original version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.7/bin:${PATH}"
PATH="/usr/java/jdk1.6.0_10/bin:${PATH}"
export PATH
