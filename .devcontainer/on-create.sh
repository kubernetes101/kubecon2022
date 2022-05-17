#!/bin/bash

# this runs as part of pre-build

echo "on-create start"
echo "$(date +'%Y-%m-%d %H:%M:%S')    on-create start" >> "$HOME/status"

# Change shell to zsh for vscode
sudo chsh --shell /bin/zsh vscode

export REPO_BASE=$PWD
export PATH="$PATH:$REPO_BASE/bin"

mkdir -p "$HOME/.ssh"
mkdir -p "$HOME/.oh-my-zsh/completions"

{
    # add cli to path
    echo "export PATH=\$PATH:$REPO_BASE/bin"

    echo "export REPO_BASE=$REPO_BASE"
    echo "export AKDC_WEBV=ghcr.io/kubernetes101/webv-red:latest"
    echo "compinit"
} >> "$HOME/.zshrc"

# make sure everything is up to date
sudo apt-get update

# only run apt upgrade on pre-build
if [ "$CODESPACE_NAME" = "null" ]
then
    echo "$(date +'%Y-%m-%d %H:%M:%S')    upgrading" >> "$HOME/status"
    sudo apt-get upgrade -y
    sudo apt-get autoremove -y
    sudo apt-get clean -y
fi

# create local registry
docker network create k3d
k3d registry create registry.localhost --port 5500
docker network connect k3d k3d-registry.localhost

# update the base docker images
docker pull ghcr.io/kubernetes101/webv-red:latest

echo "installing flux binary"
sudo rm -f /usr/local/bin/flux
curl --location --silent --output /tmp/flux.tar.gz "https://github.com/fluxcd/flux2/releases/download/v0.29.5/flux_0.29.5_linux_amd64.tar.gz"
sudo tar --extract --gzip --directory /usr/local/bin --file /tmp/flux.tar.gz
rm /tmp/flux.tar.gz

echo "completions"
kic completion zsh > "$HOME/.oh-my-zsh/completions/_kic"
k3d completion zsh > "$HOME/.oh-my-zsh/completions/_k3d"
kubectl completion zsh > "$HOME/.oh-my-zsh/completions/_kubectl"
flux completion zsh > "$HOME/.oh-my-zsh/completions/_flux"

echo "creating k3d cluster"
kic cluster create

echo "creating installing"
flux install >> "$HOME/status"

echo "on-create complete"
echo "$(date +'%Y-%m-%d %H:%M:%S')    on-create complete" >> "$HOME/status"
