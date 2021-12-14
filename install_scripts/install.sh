#!/bin/sh

# Removes exiting gitconfig and symlinks the .gitconfig from .dotfiles
rm $HOME/.gitconfig
ln -s $HOME/.dotfiles/.gitconfig $HOME/.gitconfig

# Removes exiting rgignore and symlinks the .rgignore from .dotfiles
rm $HOME/.rgignore
ln -s $HOME/.dotfiles/.rgignore $HOME/.rgignore

# Removes .vimrc from $HOME (if it exists) and symlinks the .vimrc file from the .dotfiles
rm $HOME/.vimrc
ln -s $HOME/.dotfiles/.vimrc $HOME/.vimrc

# configure for nvim
rm $HOME/.config/nvim/init.vim
ln -s $HOME/.dotfiles/init.vim $HOME/.config/nvim/init.vim

# configure kitty
rm $HOME/.config/kitty/kitty.conf
mkdir -p $HOME/.config/kitty
ln -s $HOME/.dotfiles/kitty.conf $HOME/.config/kitty/kitty.conf

# install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

# TODO run OS install script