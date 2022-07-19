# TODO look into getting sudo access before running
sudo -v

# Make fish the default shell environment
sudo chsh -s $(which fish)

# install fisher
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher

# remove existing configuration for fish
rm $HOME/.config/fish/fish_plugins
rm $HOME/.config/fish/*.fish

# link dotfile config
mkdir -p $HOME/.config/fish
ln -s  $HOME/.dotfiles/fish_config/*.fish $HOME/.config/fish
ln -s  $HOME/.dotfiles/fish_config/fish_plugins $HOME/.config/fish
