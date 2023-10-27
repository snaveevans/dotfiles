#!/bin/sh

# Removes exiting gitconfig and symlinks the .gitconfig from .dotfiles
rm $HOME/.gitconfig
ln -s $HOME/.dotfiles/.gitconfig $HOME/.gitconfig

# Removes exiting rgignore and symlinks the .rgignore from .dotfiles
rm $HOME/.rgignore
ln -s $HOME/.dotfiles/.rgignore $HOME/.rgignore

# configure for nvim
rm -rf $HOME/.config/nvim
mkdir -p $HOME/.config/nvim
ln -s $HOME/.dotfiles/nvim/* $HOME/.config/nvim

# configure kitty
rm $HOME/.config/kitty/kitty.conf
mkdir -p $HOME/.config/kitty
ln -s $HOME/.dotfiles/kitty.conf $HOME/.config/kitty/kitty.conf

# configure tmux
rm $HOME/.tmux.conf
ln -s $HOME/.dotfiles/tmux/config $HOME/.tmux.conf

mkdir -p $HOME/.local/bin

# configure local bin
ln -s $HOME/.dotfiles/bin/* $HOME/.local/bin

# configure npm
ln -s $HOME/.dotfiles/.npmrc $HOME/.npmrc

./zsh_config/install.sh

# TODO: call os install script

# post os install
# volta install node

./node.sh
