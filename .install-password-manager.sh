#!/bin/sh

# exit immediately if password-manager-binary is already in $PATH
type password-manager-binary >/dev/null 2>&1 && exit

case "$(uname -s)" in
Darwin)
  # commands to install password-manager-binary on Darwin
  brew install --cask bitwarden
  brew install bitwarden-cli
  export BW_SESSION=$(bw unlock --raw)
  ;;
Linux)
  # commands to install password-manager-binary on Linux
  ;;
*)
  echo "unsupported OS"
  exit 1
  ;;
esac
