#!/bin/sh

# Removes exiting gitconfig and symlinks the .gitconfig from .dotfiles
rm $HOME/.gitconfig
ln -s $HOME/.dotfiles/.gitconfig $HOME/.gitconfig

# Removes exiting rgignore and symlinks the .rgignore from .dotfiles
rm $HOME/.rgignore
ln -s $HOME/.dotfiles/.rgignore $HOME/.rgignore

# configure for nvim
rm $HOME/.config/nvim/init.vim
mkdir -p $HOME/.config/nvim
ln -s $HOME/.dotfiles/init.vim $HOME/.config/nvim/init.vim

# configure kitty
rm $HOME/.config/kitty/kitty.conf
mkdir -p $HOME/.config/kitty
ln -s $HOME/.dotfiles/kitty.conf $HOME/.config/kitty/kitty.conf

# install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

# TODO run OS install script
