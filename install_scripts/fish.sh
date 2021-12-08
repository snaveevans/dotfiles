# TODO look into getting sudo access before running
sudo -v

# Make fish the default shell environment
sudo chsh -s $(which fish)

# install fisher
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher

# remove existing configuration for fish
rm $HOME/.config/fish/fish_plugins
# link dotfile config
# TODO verify fish config location
ln -s $HOME/.dotfiles/fish_config/* $HOME/.config/fish/conf.d
