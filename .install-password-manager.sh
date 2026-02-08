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
  # commands to install password-manager-binary on Linux
  ;;
*)
  echo "unsupported OS"
  exit 1
  ;;
esac
