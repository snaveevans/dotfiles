#!/bin/sh

sudo add-apt-repository -y ppa:regolith-linux/release

sudo apt-get update

sudo apt-get install -yqq fish i3-gaps autojump ripgrep fzf neovim

#curl -o $HOME/ https://github.com/sharkdp/bat/releases/download/v0.21.0/bat_0.21.0_amd64.deb
#sudo dpkg -i  $HOME/bat.deb
#rm $HOME/bat.deb

# configuration for i3
rm -rf $HOME/.config/i3
mkdir -p $HOME/.config/i3
ln -s $HOME/.dotfiles/linux/i3.config $HOME/.config/i3/config

# configuration for xmodmap
rm $HOME/.Xmodmap
ln -s $HOME/.dotfiles/linux/Xmodmap $HOME/.Xmodmap

# configuration for desktop environment
rm $HOME/.dmrc
ln -s $HOME/.dotfiles/linux/dmrc $HOME/.dmrc