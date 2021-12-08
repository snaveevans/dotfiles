#!/bin/sh

sudo apt-get update

sudo apt-get install fish
sudo apt-get install i3-gaps
sudo apt-get install autojump
sudo apt-get install ripgrep
sudo apt-get install fzf
sudo apt-get install neovim
# sudo apt-get install bat

# configuration for i3
rm -rf $HOME/.config/i3
mkdir -p $HOME/.config/i3
ln -s $HOME/.dotfiles/linux/i3.config $HOME/.config/i3/config

# configuration for xmodmap
rm $HOME/.Xmodmap
ln -s $HOME/.dotfiles/linux/Xmodmap $HOME/.Xmodmap
