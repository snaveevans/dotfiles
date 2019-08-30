#!/bin/sh

echo "Setting up your Mac..."

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install Xcode command line tools
xcode-select --install

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle

# Make ZSH the default shell environment
chsh -s $(which zsh)

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Create a Sites directory
# This is a default directory for macOS user accounts but doesn't comes pre-installed
mkdir $HOME/Sites

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
rm -rf $HOME/.zshrc
ln -s $HOME/.dotfiles/.zshrc $HOME/.zshrc

# Removes .vimrc from $HOME (if it exists) and symlinks the .vimrc file from the .dotfiles
rm -rf $HOME/.vimrc
ln -s $HOME/.dotfiles/.vimrc $HOME/.vimrc

# Removes .yabairc from $HOME (if it exists) and symlinks the .yabairc file from the .dotfiles
rm -rf $HOME/.yabairc
ln -s $HOME/.dotfiles/.yabairc $HOME/.yabairc

# Removes .skhdrc from $HOME (if it exists) and symlinks the .skhdrc file from the .dotfiles
rm -rf $HOME/.skhdrc
ln -s $HOME/.dotfiles/.skhdrc $HOME/.skhdrc

# Removes coc-settings.json from $HOME/.vim (if it exists) and symlinks the coc-settings.json file from the .dotfiles
rm -rf $HOME/.vim/coc-settings.json
ln -s $HOME/.dotfiles/coc-settings.json $HOME/.vim/coc-settings.json
# configure for nvim
ln -s $HOME/.dotfiles/init.vim $HOME/.config/nvim/init.vim
ln -s $HOME/.dotfiles/coc-settings.json $HOME/.config/nvim/coc-settings.json

# zsh-syntax-highlighting doesn't like brew installation
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# fzf key bindings
$(brew --prefix)/opt/fzf/install --all

# Set macOS preferences
# We will run this last because this will reload the shell
source macos.sh
