#!/bin/bash

sudo apt -qy install curl git jq lz4 build-essential
sudo apt install make clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop -y
sudo apt install curl -y
sudo apt install ncdu -y
sudo apt-get update -q
sudo apt install htop mc curl tar wget jq bsdmainutils git make ncdu gcc jq chrony net-tools iotop nload clang libpq-dev libssl-dev build-essential pkg-config openssl ocl-icd-opencl-dev libopencl-clang-dev libgomp1 -y
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade
sudo apt install make clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop -y
sudo apt install curl -y
sudo apt-get install -qy ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings

# Обновление установленных пакетов
sudo apt -qy upgrade

# Клонирование и установка последней версии Go
git clone --depth 1 https://github.com/udhos/update-golang
cd update-golang
git fetch --unshallow
sudo ./update-golang.sh
cd
rm -rf update-golang

# Установка Docker
if ! command -v docker &> /dev/null
then
sudo apt-get update -q
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo service docker start
fi

# Установка Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y

# Установка NVM и Node.js
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install 21.7.1

# Установка Python
sudo apt install python3 -y