sudo -v

# Make ZSH the default shell environment
sudo chsh -s $(which zsh) $USER

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

link zshrc
rm $HOME/.zshrc
ln -s $HOME/.dotfiles/zsh_config/zshrc $HOME/.zshrc

# link zshenv
rm $HOME/.zshenv
ln -s $HOME/.dotfiles/zsh_config/zshenv $HOME/.zshenv

git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab

# zsh theme
rm -rf "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
git clone https://github.com/spaceship-prompt/spaceship-vi-mode.git $ZSH_CUSTOM/plugins/spaceship-vi-mode
