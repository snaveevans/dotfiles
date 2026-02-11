#!/bin/sh

# exit immediately if bw is already in $PATH
type bw >/dev/null 2>&1 && exit

case "$(uname -s)" in
Darwin)
  # commands to install Bitwarden on Darwin
  brew install --cask bitwarden
  brew install bitwarden-cli
  ;;
Linux)
  # Install Bitwarden CLI on Linux using snap or direct download
  if command -v snap >/dev/null 2>&1; then
    sudo snap install bw
  else
    # Download and install directly
    curl -L "https://vault.bitwarden.com/download/?app=cli&platform=linux" -o /tmp/bw.zip
    unzip /tmp/bw.zip -d /tmp/
    sudo mv /tmp/bw /usr/local/bin/bw
    sudo chmod +x /usr/local/bin/bw
    rm /tmp/bw.zip
  fi
  ;;
*)
  echo "unsupported OS"
  exit 1
  ;;
esac
