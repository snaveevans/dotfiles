#!/bin/sh

sudo apt-get update

if test ! $(which fish); then
  sudo apt-get install fish
fi

if test ! $(which i3); then
  sudo apt-get install i3-gaps
fi

# configuration for i3
rm -rf $HOME/.config/i3
mkdir -p $HOME/.config/i3
ln -s $HOME/.dotfiles/linux/i3.config $HOME/.config/i3/config

# configuration for xmodmap
rm $HOME/.Xmodmap
ln -s $HOME/.dotfiles/linux/Xmodmap $HOME/.Xmodmap
